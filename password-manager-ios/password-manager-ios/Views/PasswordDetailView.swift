import SwiftUI
import CryptoKit

struct PasswordDetailView: View {
    @State var entry: VaultEntry
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var vaultManager: LocalVaultManager

    @State private var isEditing: Bool = false
    @State private var editableTitle: String = ""
    @State private var editableUsername: String = ""
    @State private var editableWebsite: String = ""
    @State private var editablePassword: String = ""
    @State private var editableNotes: String = ""
    @State private var editableCategory: String = "Social"
    @State private var editableCustomCategory: String = ""

    // Kopiowanie
    @State private var copiedField: String? = nil
    @State private var clipboardCountdown: Int = 0
    @State private var countdownTask: Task<Void, Never>? = nil

    // Breach detection
    @State private var breachCount: Int? = nil
    @State private var isCheckingBreach: Bool = false

    let categories = ["Finance", "Social", "Work", "School", "Gaming", "Shopping", "Custom"]

    private func getDecryptedPassword() -> String {
        vaultManager.decryptEntry(entry: entry, masterKey: authManager.currentMasterKey) ?? "Error decrypting"
    }

    private func getDecryptedNotes() -> String {
        vaultManager.decryptNotes(entry: entry, masterKey: authManager.currentMasterKey) ?? ""
    }

    var onDelete: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: entry.iconName)
                                .foregroundColor(.green)
                                .font(.system(size: 32))
                        }
                        VStack(spacing: 4) {
                            if isEditing {
                                TextField("Title", text: $editableTitle)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                    .cornerRadius(10)
                            } else {
                                Text(entry.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("LAST MODIFIED \(entry.lastModified)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)

                    // Breach banner
                    if let count = breachCount {
                        BreachBanner(count: count)
                    } else if isCheckingBreach {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.7).tint(.gray)
                            Text("Checking for breaches...")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(10)
                    }

                    // Clipboard countdown banner
                    if clipboardCountdown > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("Clipboard clears in \(clipboardCountdown)s")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = ""
                                ClipboardManager.shared.cancelClear()
                                countdownTask?.cancel()
                                clipboardCountdown = 0
                            }) {
                                Text("Clear now")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Fields
                    VStack(spacing: 16) {
                        DetailRow(label: "USERNAME", value: $editableUsername, isEditing: isEditing,
                                  isCopyable: true, copiedField: $copiedField, fieldKey: "username",
                                  onCopy: { copyToClipboard(editableUsername, fieldName: "Username") })

                        DetailRow(label: "PASSWORD", value: $editablePassword, isEditing: isEditing,
                                  isCopyable: true, isSecure: true, copiedField: $copiedField, fieldKey: "password",
                                  onCopy: { copyToClipboard(editablePassword, fieldName: "Password") })

                        DetailRow(label: "WEBSITE", value: $editableWebsite, isEditing: isEditing,
                                  copiedField: $copiedField, fieldKey: "website", onCopy: {})

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("NOTES").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)
                                Spacer()
                                if isEditing {
                                    Text("\(editableNotes.count)/250")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(editableNotes.count > 220 ? .orange : .gray)
                                }
                            }

                            if isEditing {
                                ZStack(alignment: .topLeading) {
                                    if editableNotes.isEmpty {
                                        Text("Add secure notes...")
                                            .font(.system(size: 14)).foregroundColor(.gray.opacity(0.5))
                                            .padding(.top, 8).padding(.leading, 4)
                                    }
                                    TextEditor(text: $editableNotes)
                                        .foregroundColor(.white).font(.system(size: 14))
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 80, maxHeight: 120)
                                        .onChange(of: editableNotes) { val in
                                            if val.count > 250 { editableNotes = String(val.prefix(250)) }
                                        }
                                }
                                .padding(12)
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.3), lineWidth: 1))
                            } else {
                                if editableNotes.isEmpty {
                                    Text("No notes").font(.system(size: 14)).foregroundColor(.gray.opacity(0.5))
                                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(red: 0.16, green: 0.16, blue: 0.17)).cornerRadius(12)
                                } else {
                                    HStack(alignment: .top) {
                                        Text(editableNotes).font(.system(size: 14)).foregroundColor(.white)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                        Button(action: { copyToClipboard(editableNotes, fieldName: "Notes") }) {
                                            Image(systemName: copiedField == "Notes" ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 14))
                                                .foregroundColor(copiedField == "Notes" ? .green : Color(red: 0.51, green: 0.51, blue: 1))
                                        }
                                    }
                                    .padding()
                                    .background(Color(red: 0.16, green: 0.16, blue: 0.17)).cornerRadius(12)
                                }
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill").font(.system(size: 10))
                                Text("Encrypted with AES-GCM").font(.system(size: 11))
                            }
                            .foregroundColor(.gray.opacity(0.5))
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)

                            if isEditing {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(action: { editableCategory = cat }) {
                                            Text(cat == "Custom" ? "✏️ Custom" : cat)
                                                .font(.system(size: 12, weight: .semibold)).lineLimit(1)
                                                .padding(.vertical, 8).frame(maxWidth: .infinity)
                                                .background(editableCategory == cat ? Color(red: 0.51, green: 0.51, blue: 1) : Color(red: 0.16, green: 0.16, blue: 0.17))
                                                .foregroundColor(editableCategory == cat ? .black : .gray)
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                                if editableCategory == "Custom" {
                                    TextField("Custom category name", text: $editableCustomCategory)
                                        .foregroundColor(.white).padding()
                                        .background(Color(red: 0.16, green: 0.16, blue: 0.17)).cornerRadius(12)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            } else {
                                Text(entry.effectiveCategory.uppercased())
                                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(red: 0.16, green: 0.16, blue: 0.17)).cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: editableCategory)
                    }

                    // Delete
                    if !isEditing {
                        Button(action: {
                            if let token = authManager.currentAPIToken,
                               let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                vaultManager.removeEntry(at: IndexSet(integer: index), token: token)
                                dismiss()
                            }
                        }) {
                            Label("Delete Entry", systemImage: "trash.fill")
                                .foregroundColor(.red).padding()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            setupEditableFields()
            checkBreachStatus()
        }
        .onDisappear {
            countdownTask?.cancel()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { saveChanges() } else { isEditing = true }
                }
                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                .font(.system(size: 16, weight: .bold))
            }
        }
        .overlay(alignment: .bottom) {
            if let field = copiedField {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("\(field) copied")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 10)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: copiedField)
            }
        }
    }

    // MARK: - Copy z auto-clear i countdown
    private func copyToClipboard(_ value: String, fieldName: String) {
        ClipboardManager.shared.copy(value)

        withAnimation(.spring()) { copiedField = fieldName }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copiedField = nil }
        }

        // Countdown UI
        countdownTask?.cancel()
        clipboardCountdown = 30
        countdownTask = Task {
            for i in stride(from: 30, through: 0, by: -1) {
                guard !Task.isCancelled else { return }
                await MainActor.run { clipboardCountdown = i }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            await MainActor.run {
                withAnimation { clipboardCountdown = 0 }
            }
        }
    }

    // MARK: - Breach check
    private func checkBreachStatus() {
        let password = getDecryptedPassword()
        guard !password.isEmpty, password != "Error decrypting" else { return }

        isCheckingBreach = true
        breachCount = nil

        Task {
            let result = await BreachService.shared.isPasswordBreached(password)
            DispatchQueue.main.async {
                isCheckingBreach = false
                switch result {
                case .success(let count):
                    breachCount = count
                case .failure:
                    breachCount = nil // cicha porażka — brak sieci itp.
                }
            }
        }
    }

    // MARK: - Setup & Save
    private func setupEditableFields() {
        editableTitle = entry.title
        editableUsername = entry.username
        editableWebsite = entry.website
        editablePassword = getDecryptedPassword()
        editableNotes = getDecryptedNotes()
        editableCategory = entry.category.isEmpty ? "Social" : entry.category
        editableCustomCategory = entry.customCategory ?? ""
    }

    private func saveChanges() {
        guard let key = authManager.currentMasterKey else { return }

        if let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
            vaultManager.entries[index].title = editableTitle
            vaultManager.entries[index].username = editableUsername
            vaultManager.entries[index].website = editableWebsite
            vaultManager.entries[index].category = editableCategory
            vaultManager.entries[index].customCategory = editableCategory == "Custom" ? editableCustomCategory : nil

            if editablePassword != getDecryptedPassword() {
                if let encrypted = try? CryptoService.encrypt(plaintext: editablePassword, using: key) {
                    vaultManager.entries[index].ciphertext = encrypted.ciphertext
                    vaultManager.entries[index].nonce = encrypted.nonce
                }
                // Sprawdź breach po zmianie hasła
                breachCount = nil
                checkBreachStatus()
            }

            if editableNotes.isEmpty {
                vaultManager.entries[index].notesCiphertext = nil
                vaultManager.entries[index].notesNonce = nil
            } else if editableNotes != getDecryptedNotes() {
                if let encryptedNotes = try? CryptoService.encrypt(plaintext: editableNotes, using: key) {
                    vaultManager.entries[index].notesCiphertext = encryptedNotes.ciphertext
                    vaultManager.entries[index].notesNonce = encryptedNotes.nonce
                }
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            vaultManager.entries[index].lastModified = formatter.string(from: Date()).uppercased()
            self.entry = vaultManager.entries[index]
        }

        vaultManager.saveToOfflineCache()
        if let token = authManager.currentAPIToken {
            vaultManager.updateEntryOnServer(entry: self.entry, token: token)
        }
        isEditing = false
    }
}

// MARK: - BreachBanner
struct BreachBanner: View {
    let count: Int

    var body: some View {
        if count == 0 {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Password not found in breaches")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Checked via Have I Been Pwned")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.green.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.2), lineWidth: 1))
        } else {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Password found in \(count.formatted()) data breaches")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Change this password immediately")
                        .font(.system(size: 11))
                        .foregroundColor(Color.red.opacity(0.8))
                }
                Spacer()
            }
            .padding(12)
            .background(Color.red.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
        }
    }
}

// MARK: - DetailRow
struct DetailRow: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    var isCopyable: Bool = false
    var isSecure: Bool = false
    var actionIcon: String? = nil
    @Binding var copiedField: String?
    var fieldKey: String = ""
    var onCopy: () -> Void = {}

    @State private var showPlaintext = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(.gray)

            HStack {
                if isEditing {
                    if isSecure && !showPlaintext {
                        SecureField("", text: $value).foregroundColor(.white)
                            .font(.system(size: 14, design: .monospaced))
                    } else {
                        TextField("", text: $value).foregroundColor(.white).autocapitalization(.none)
                            .font(.system(size: 14, design: isSecure ? .monospaced : .default))
                    }
                } else {
                    Text(isSecure && !showPlaintext ? "••••••••" : value)
                        .foregroundColor(.white)
                        .font(.system(size: 14, design: isSecure ? .monospaced : .default))
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 12) {
                    if isSecure {
                        Button(action: { showPlaintext.toggle() }) {
                            Image(systemName: showPlaintext ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14)).foregroundColor(.gray)
                        }
                    }
                    if isCopyable && !isEditing {
                        Button(action: onCopy) {
                            Image(systemName: copiedField == label.capitalized ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(copiedField == label.capitalized ? .green : Color(red: 0.51, green: 0.51, blue: 1))
                                .animation(.easeInOut, value: copiedField)
                        }
                    }
                }
            }
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                isEditing ? Color(red: 0.51, green: 0.51, blue: 1).opacity(0.3) : Color.clear, lineWidth: 1))
        }
    }
}
