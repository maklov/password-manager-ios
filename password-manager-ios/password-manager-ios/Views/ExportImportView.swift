import SwiftUI
import UniformTypeIdentifiers

// Typ pliku .vault66
extension UTType {
    static let vault66 = UTType(exportedAs: "com.maklov.vault66")
}

struct ExportImportView: View {
    @EnvironmentObject var vaultManager: LocalVaultManager
    @EnvironmentObject var authManager: AuthManager

    // Export
    @State private var showExportSheet = false
    @State private var exportPassword = ""
    @State private var exportPasswordConfirm = ""
    @State private var exportError: String? = nil
    @State private var exportedFileURL: URL? = nil
    @State private var showShareSheet = false
    @State private var isExporting = false

    // Import
    @State private var showImportPicker = false
    @State private var importPassword = ""
    @State private var importError: String? = nil
    @State private var importSuccess: String? = nil
    @State private var showImportSheet = false
    @State private var pendingImportURL: URL? = nil
    @State private var isImporting = false

    // Confirmations
    @State private var showImportConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Backup &\nRestore")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(.white)

                            Text("Export your vault as an encrypted .vault66 file. Import to restore on any device.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        // Info card
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("End-to-end encrypted backup")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("The .vault66 file is encrypted with AES-GCM. Without the export password, the file is unreadable — even by us.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(14)
                        .background(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.08))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.2), lineWidth: 1))

                        // Export section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EXPORT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)

                            VStack(spacing: 0) {
                                Button(action: { showExportSheet = true }) {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.green.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundColor(.green)
                                                .font(.system(size: 16))
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Export Vault")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text("\(vaultManager.entries.count) entries will be exported")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(14)
                                }

                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)

                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.08))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "doc.badge.clock")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Format")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                        Text(".vault66 — AES-GCM encrypted JSON")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                            }
                            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                            .cornerRadius(14)
                        }

                        // Import section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IMPORT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)

                            VStack(spacing: 0) {
                                Button(action: { showImportPicker = true }) {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "square.and.arrow.down")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Import from .vault66")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text("Entries will be merged with current vault")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(14)
                                }

                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)

                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.08))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 14))
                                    }
                                    Text("Import adds entries alongside existing ones — it does not replace your vault.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(14)
                            }
                            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                            .cornerRadius(14)
                        }

                        // Success/Error feedback
                        if let success = importSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text(success).font(.system(size: 13)).foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.08))
                            .cornerRadius(10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        // EXPORT SHEET
        .sheet(isPresented: $showExportSheet) {
            ExportPasswordSheet(
                password: $exportPassword,
                confirm: $exportPasswordConfirm,
                error: $exportError,
                isExporting: $isExporting,
                onExport: performExport,
                onDismiss: { showExportSheet = false; exportPassword = ""; exportPasswordConfirm = ""; exportError = nil }
            )
        }
        // SHARE SHEET
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        // IMPORT FILE PICKER
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    pendingImportURL = url
                    showImportSheet = true
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        // IMPORT PASSWORD SHEET
        .sheet(isPresented: $showImportSheet) {
            ImportPasswordSheet(
                password: $importPassword,
                error: $importError,
                isImporting: $isImporting,
                onImport: performImport,
                onDismiss: { showImportSheet = false; importPassword = ""; importError = nil }
            )
        }
        .animation(.easeInOut, value: importSuccess)
    }

    // MARK: - Export logic
    private func performExport() {
        guard exportPassword == exportPasswordConfirm else {
            exportError = "Passwords do not match"
            return
        }
        guard exportPassword.count >= 8 else {
            exportError = "Export password must be at least 8 characters"
            return
        }

        isExporting = true
        exportError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try VaultExportService.shared.exportVault(
                    entries: vaultManager.entries,
                    password: exportPassword
                )

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HHmm"
                let filename = "vault66_backup_\(formatter.string(from: Date())).vault66"

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: tempURL)

                DispatchQueue.main.async {
                    isExporting = false
                    exportedFileURL = tempURL
                    exportPassword = ""
                    exportPasswordConfirm = ""
                    showExportSheet = false
                    // Dłuższe opóźnienie — czekamy aż sheet z hasłem w pełni zniknie
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showShareSheet = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Import logic
    private func performImport() {
        guard let url = pendingImportURL else { return }

        isImporting = true
        importError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Security-scoped resource access
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }

                let data = try Data(contentsOf: url)
                let imported = try VaultExportService.shared.importVault(data: data, password: importPassword)

                DispatchQueue.main.async {
                    isImporting = false
                    showImportSheet = false
                    importPassword = ""

                    // Scal z istniejącymi — unikaj duplikatów po tytule+username
                    let existingKeys = Set(vaultManager.entries.map { "\($0.title)_\($0.username)" })
                    let newEntries = imported.filter { !existingKeys.contains("\($0.title)_\($0.username)") }

                    vaultManager.entries.append(contentsOf: newEntries)
                    vaultManager.saveToOfflineCache()

                    // Push na serwer
                    if let token = authManager.currentAPIToken {
                        for entry in newEntries {
                            vaultManager.pushChangesToServer(entry: entry, token: token)
                        }
                    }

                    withAnimation {
                        importSuccess = "✓ Imported \(newEntries.count) entries successfully"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { importSuccess = nil }
                    }
                }
            } catch let error as VaultExportService.ExportError {
                DispatchQueue.main.async {
                    isImporting = false
                    importError = error.errorDescription
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    importError = "Could not read file: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Export Password Sheet
struct ExportPasswordSheet: View {
    @Binding var password: String
    @Binding var confirm: String
    @Binding var error: String?
    @Binding var isExporting: Bool
    let onExport: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                        Text("Set Export Password")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("This password protects your backup file.\nStore it safely — it's required to import.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        ValidatedField(
                            title: "EXPORT PASSWORD",
                            placeholder: "Min. 8 characters",
                            text: $password,
                            isSecure: true,
                            submitLabel: .next
                        )
                        ValidatedField(
                            title: "CONFIRM PASSWORD",
                            placeholder: "Repeat password",
                            text: $confirm,
                            error: confirm.isEmpty ? nil : (confirm == password ? nil : "Passwords do not match"),
                            isSecure: true,
                            submitLabel: .done,
                            onSubmit: onExport
                        )

                        if let err = error {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 12))
                                Text(err).font(.system(size: 12))
                            }
                            .foregroundColor(.red)
                        }
                    }

                    Button(action: onExport) {
                        HStack {
                            if isExporting {
                                ProgressView().tint(.black).scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export .vault66")
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.51, green: 0.51, blue: 1))
                        .cornerRadius(12)
                    }
                    .disabled(password.count < 8 || password != confirm || isExporting)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Export Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss).foregroundColor(.gray)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Import Password Sheet
struct ImportPasswordSheet: View {
    @Binding var password: String
    @Binding var error: String?
    @Binding var isImporting: Bool
    let onImport: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Enter Export Password")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("Enter the password used when this backup was created.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        ValidatedField(
                            title: "EXPORT PASSWORD",
                            placeholder: "••••••••",
                            text: $password,
                            error: error,
                            isSecure: true,
                            submitLabel: .done,
                            onSubmit: onImport,
                            onEditingChanged: { error = nil }
                        )
                    }

                    Button(action: onImport) {
                        HStack {
                            if isImporting {
                                ProgressView().tint(.black).scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Vault")
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(password.isEmpty ? Color(red: 0.16, green: 0.16, blue: 0.17) : Color(red: 0.51, green: 0.51, blue: 1))
                        .cornerRadius(12)
                    }
                    .disabled(password.isEmpty || isImporting)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Import Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss).foregroundColor(.gray)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
