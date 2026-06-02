import SwiftUI

struct SecuritySettingsView: View {
    @EnvironmentObject var navState: AppNavigationState
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var autoLockManager: AutoLockManager
    @EnvironmentObject var vaultManager: LocalVaultManager

    @AppStorage("biometric_unlock_enabled") private var biometricUnlockEnabled: Bool = false
    @State private var selectedTimeout: AutoLockTimeout = .oneMinute

    @State private var report: PasswordHealthReport? = nil
    @State private var isAnalyzing: Bool = false
    @State private var expandedSection: HealthSection? = nil

    // Nawigacja do edycji wpisu
    @State private var entryToEdit: VaultEntry? = nil

    enum HealthSection { case weak, duplicates }

    var body: some View {
        NavigationStack {
            NavigationLink(
                destination: Group {
                    if let entry = entryToEdit {
                        PasswordDetailView(entry: entry, onDelete: {
                            if let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                vaultManager.removeEntry(at: IndexSet(integer: index), token: authManager.currentAPIToken ?? "")
                            }
                            entryToEdit = nil
                            runAnalysis()
                        })
                        .environmentObject(vaultManager)
                        .environmentObject(authManager)
                    }
                },
                isActive: Binding(
                    get: { entryToEdit != nil },
                    set: { if !$0 { entryToEdit = nil; runAnalysis() } }
                )
            ) { EmptyView() }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Text("Encryption\nThresholds")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text("Define the perimeter of your digital sanctuary with high-fidelity biometric and structural protocols.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    // --- PASSWORD HEALTH ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PASSWORD HEALTH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)

                        if isAnalyzing {
                            HStack {
                                ProgressView().tint(.gray)
                                Text("Analyzing vault...").font(.system(size: 14)).foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                        } else if let report = report {
                            VStack(spacing: 12) {
                                // Score
                                HStack(alignment: .center, spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white.opacity(0.08), lineWidth: 8)
                                            .frame(width: 80, height: 80)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(report.score) / 100)
                                            .stroke(scoreColor(report.scoreColor), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                            .frame(width: 80, height: 80)
                                            .rotationEffect(.degrees(-90))
                                            .animation(.easeInOut(duration: 0.8), value: report.score)
                                        VStack(spacing: 0) {
                                            Text("\(report.score)")
                                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("%")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(report.scoreLabel)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(scoreColor(report.scoreColor))
                                        Text("\(report.totalEntries) passwords analyzed")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                        if report.score == 100 {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.shield.fill").foregroundColor(.green)
                                                Text("All passwords secure").font(.system(size: 12)).foregroundColor(.green)
                                            }
                                        }
                                    }
                                    Spacer()
                                }

                                Divider().background(Color.white.opacity(0.08))

                                // Weak
                                HealthRow(
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red,
                                    title: "Weak Passwords",
                                    subtitle: "Less than 8 characters",
                                    count: report.weakEntries.count,
                                    isExpanded: expandedSection == .weak,
                                    onTap: {
                                        withAnimation {
                                            expandedSection = expandedSection == .weak ? nil : .weak
                                        }
                                    }
                                )

                                if expandedSection == .weak && !report.weakEntries.isEmpty {
                                    HealthEntryList(entries: report.weakEntries) { entry in
                                        entryToEdit = entry
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                Divider().background(Color.white.opacity(0.05))

                                // Duplicates
                                HealthRow(
                                    icon: "doc.on.doc.fill",
                                    color: .orange,
                                    title: "Reused Passwords",
                                    subtitle: "Same password in multiple entries",
                                    count: report.duplicateEntries.count,
                                    isExpanded: expandedSection == .duplicates,
                                    onTap: {
                                        withAnimation {
                                            expandedSection = expandedSection == .duplicates ? nil : .duplicates
                                        }
                                    }
                                )

                                if expandedSection == .duplicates && !report.duplicateEntries.isEmpty {
                                    HealthEntryList(entries: report.duplicateEntries) { entry in
                                        entryToEdit = entry
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)

                            Button(action: runAnalysis) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
                                    Text("Re-analyze").font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                            }
                        } else {
                            Button(action: runAnalysis) {
                                HStack {
                                    Image(systemName: "shield.lefthalf.filled")
                                    Text("Analyze Vault Health")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.51, green: 0.51, blue: 1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // --- SECURITY SETTINGS ---
                    VStack(spacing: 1) {
                        SecurityToggle(
                            title: "Biometric Unlock",
                            subtitle: "FaceID / TouchID Protocol",
                            isOn: $biometricUnlockEnabled,
                            icon: "faceid"
                        )

                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)

                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "timer").foregroundColor(.blue).frame(width: 30)
                                VStack(alignment: .leading) {
                                    Text("Auto-lock Timeout").font(.headline)
                                    Text("Lock vault after inactivity").font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding()

                            VStack(spacing: 2) {
                                ForEach(AutoLockTimeout.allCases) { timeout in
                                    Button(action: {
                                        selectedTimeout = timeout
                                        autoLockManager.selectedTimeout = timeout
                                        if timeout != .immediately {
                                            autoLockManager.resetActivityTimer()
                                        }
                                    }) {
                                        HStack {
                                            Text(timeout.label).font(.system(size: 15)).foregroundColor(.white)
                                            Spacer()
                                            if selectedTimeout == timeout {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                            }
                                        }
                                        .padding(.horizontal, 20).padding(.vertical, 12)
                                        .background(selectedTimeout == timeout
                                            ? Color(red: 0.51, green: 0.51, blue: 1).opacity(0.08)
                                            : Color.clear)
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(20)

                    // Lock
                    Button(action: {
                        authManager.logout()
                        autoLockManager.onAppLogout()
                        navState.currentRoute = .welcome
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Lock Vault & Disconnect")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(16)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .padding(24)
            }
            .background(Color(red: 0.07, green: 0.07, blue: 0.08))
        }
        .onAppear {
            selectedTimeout = autoLockManager.selectedTimeout
            runAnalysis()
        }
    }

    private func runAnalysis() {
        isAnalyzing = true
        report = nil
        expandedSection = nil
        DispatchQueue.global(qos: .userInitiated).async {
            let result = PasswordHealthService.shared.analyze(
                entries: vaultManager.entries,
                masterKey: authManager.currentMasterKey
            )
            DispatchQueue.main.async {
                withAnimation { self.report = result }
                self.isAnalyzing = false
            }
        }
    }

    private func scoreColor(_ name: String) -> Color {
        switch name {
        case "green":  return .green
        case "blue":   return Color(red: 0.51, green: 0.51, blue: 1)
        case "orange": return .orange
        default:       return .red
        }
    }
}

// MARK: - HealthRow
struct HealthRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let count: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(count > 0 ? color : .green)
                    .font(.system(size: 16))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.gray)
                }

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(color.opacity(0.12))
                        .cornerRadius(8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11)).foregroundColor(.gray)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green).font(.system(size: 16))
                }
            }
        }
    }
}

// MARK: - HealthEntryList z nawigacją
struct HealthEntryList: View {
    let entries: [VaultEntry]
    let onSelect: (VaultEntry) -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(entries) { entry in
                Button(action: { onSelect(entry) }) {
                    HStack(spacing: 10) {
                        Image(systemName: entry.iconName)
                            .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            .font(.system(size: 13))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            if !entry.username.isEmpty {
                                Text(entry.username)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - SecurityToggle
struct SecurityToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    var color: Color = .blue

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(color)
        }
        .padding()
    }
}

struct SecurityRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }
        .padding()
    }
}
