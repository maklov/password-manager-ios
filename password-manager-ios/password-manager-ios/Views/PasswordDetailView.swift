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
    @State private var editableCategory: String = "General"

    // Feedback kopiowania
    @State private var copiedField: String? = nil

    let categories = ["Finance", "Social", "Work", "Notes", "General"]

    private func getDecryptedPassword() -> String {
        return vaultManager.decryptEntry(entry: entry, masterKey: authManager.currentMasterKey) ?? "Error decrypting"
    }

    var onDelete: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Nagłówek
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
                            // Title — edytowalny w trybie edycji
                            if isEditing {
                                TextField("Title", text: $editableTitle)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
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

                    // Pola
                    VStack(spacing: 16) {

                        // USERNAME z kopiowaniem
                        DetailRow(
                            label: "USERNAME",
                            value: $editableUsername,
                            isEditing: isEditing,
                            isCopyable: true,
                            copiedField: $copiedField,
                            fieldKey: "username"
                        )

                        // PASSWORD z kopiowaniem i podglądem
                        DetailRow(
                            label: "PASSWORD",
                            value: $editablePassword,
                            isEditing: isEditing,
                            isCopyable: true,
                            isSecure: true,
                            copiedField: $copiedField,
                            fieldKey: "password"
                        )

                        // WEBSITE
                        DetailRow(
                            label: "WEBSITE",
                            value: $editableWebsite,
                            isEditing: isEditing,
                            isCopyable: false,
                            copiedField: $copiedField,
                            fieldKey: "website"
                        )

                        // CATEGORY
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)

                            if isEditing {
                                Picker("Select Category", selection: $editableCategory) {
                                    ForEach(categories, id: \.self) { cat in
                                        Text(cat).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .cornerRadius(12)
                            } else {
                                Text(editableCategory.uppercased())
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
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
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }
                .padding(24)
            }
        }
        .onAppear { setupEditableFields() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { saveChanges() } else { isEditing = true }
                }
                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                .font(.system(size: 16, weight: .bold))
            }
        }
        // Toast z potwierdzeniem kopiowania
        .overlay(alignment: .bottom) {
            if let field = copiedField {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(field) copied to clipboard")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 10)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: copiedField)
            }
        }
    }

    private func setupEditableFields() {
        editableTitle = entry.title
        editableUsername = entry.username
        editableWebsite = entry.website
        editablePassword = getDecryptedPassword()
        editableCategory = entry.category.isEmpty ? "General" : entry.category
    }

    private func saveChanges() {
        guard let key = authManager.currentMasterKey else { return }

        if let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
            vaultManager.entries[index].title = editableTitle
            vaultManager.entries[index].username = editableUsername
            vaultManager.entries[index].website = editableWebsite
            vaultManager.entries[index].category = editableCategory

            if editablePassword != getDecryptedPassword() {
                do {
                    let encrypted = try CryptoService.encrypt(plaintext: editablePassword, using: key)
                    vaultManager.entries[index].ciphertext = encrypted.ciphertext
                    vaultManager.entries[index].nonce = encrypted.nonce
                } catch { print("Re-encryption failed: \(error)") }
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

    @State private var showPlaintext = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)

            HStack {
                if isEditing {
                    if isSecure && !showPlaintext {
                        SecureField("", text: $value)
                            .foregroundColor(.white)
                            .font(.system(size: 14, design: .monospaced))
                    } else {
                        TextField("", text: $value)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
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
                    // Przycisk podglądu (tylko dla pola secure)
                    if isSecure {
                        Button(action: { showPlaintext.toggle() }) {
                            Image(systemName: showPlaintext ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }

                    // Przycisk kopiowania
                    if isCopyable && !isEditing {
                        Button(action: {
                            UIPasteboard.general.string = value
                            withAnimation(.spring()) {
                                copiedField = label.capitalized
                            }
                            // Chowamy toast po 2 sekundach
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeOut) {
                                    copiedField = nil
                                }
                            }
                        }) {
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEditing ? Color(red: 0.51, green: 0.51, blue: 1).opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}
