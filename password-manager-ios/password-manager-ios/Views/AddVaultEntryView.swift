import SwiftUI

enum FocusField: Hashable {
    case title, website, username, password
}

struct AddVaultEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vaultManager: LocalVaultManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var title: String = ""
    @State private var username: String = ""
    @State private var website: String = ""
    @State private var plaintextPassword: String = ""
    @State private var selectedCategory: String = "Social"
    
    @FocusState private var focusedField: FocusField?
    
    @State private var showGenerator: Bool = false
    @State private var passwordLength: Double = 20
    @State private var useSymbols: Bool = true
    @State private var useNumbers: Bool = true
    
    let categories = ["Finance", "Social", "Work", "Notes", "General"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 16) {
                            EntryField(label: "TITLE (e.g. GitHub)", text: $title, submitLabel: .next) {
                                focusedField = .website
                            }
                            .focused($focusedField, equals: .title)
                            
                            EntryField(label: "WEBSITE (e.g. github.com)", text: $website, submitLabel: .next) {
                                focusedField = .username
                            }
                            .focused($focusedField, equals: .website)
                            
                            EntryField(label: "USERNAME OR EMAIL", text: $username, submitLabel: .next) {
                                focusedField = .password
                            }
                            .focused($focusedField, equals: .username)
                            
                            EntryField(label: "PASSWORD", text: $plaintextPassword, isSecure: true, submitLabel: .done) {
                                focusedField = nil
                            }
                            .focused($focusedField, equals: .password)
                        }
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                focusedField = nil
                                withAnimation { showGenerator.toggle() }
                            }) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Generate Strong Password")
                                    Spacer()
                                    Image(systemName: showGenerator ? "chevron.down" : "chevron.right")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                .padding()
                                .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                            }
                            
                            if showGenerator {
                                VStack(spacing: 16) {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("Length")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(Int(passwordLength))")
                                                .font(.caption).bold()
                                                .padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.2))
                                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                                .cornerRadius(8)
                                        }
                                        Slider(value: $passwordLength, in: 8...32, step: 1)
                                            .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                    }
                                    
                                    HStack(spacing: 16) {
                                        Toggle("Symbols", isOn: $useSymbols)
                                            .toggleStyle(.button)
                                            .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                        
                                        Toggle("Numbers", isOn: $useNumbers)
                                            .toggleStyle(.button)
                                            .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                        Spacer()
                                    }
                                    
                                    Button(action: {
                                        plaintextPassword = generateAppleStylePassword(
                                            length: Int(passwordLength),
                                            symbols: useSymbols,
                                            numbers: useNumbers
                                        )
                                    }) {
                                        Text("Generate & Autofill")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(red: 0.51, green: 0.51, blue: 1))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17).opacity(0.5))
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Color(red: 0.51, green: 0.51, blue: 1))
                        }
                        .padding(.top, 8)
                        
                        Button(action: {
                            saveNewEntry()
                        }) {
                            Text("Save to Vault")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(title.isEmpty || plaintextPassword.isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.51, green: 0.51, blue: 1))
                                .cornerRadius(12)
                        }
                        .disabled(title.isEmpty || plaintextPassword.isEmpty)
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                focusedField = .title
            }
        }
    }
    
    private func saveNewEntry() {
        guard let masterKey = authManager.currentMasterKey else { return }
        
        do {
            let encryptedData = try CryptoService.encrypt(plaintext: plaintextPassword, using: masterKey)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            let dateString = formatter.string(from: Date()).uppercased()
            
            let newEntry = VaultEntry(
                id: UUID().uuidString,
                title: title,
                username: username,
                website: website,
                ciphertext: encryptedData.ciphertext,
                nonce: encryptedData.nonce,
                category: selectedCategory,
                lastModified: dateString,
                iconName: "key.fill"
            )
            
            vaultManager.entries.append(newEntry)
            vaultManager.saveToOfflineCache()
            
            // PUSH NA SERWER JEŚLI MAMY TOKEN
            if let token = authManager.currentAPIToken {
                vaultManager.pushChangesToServer(entry: newEntry, token: token)

                print("[LocalVaultManager] 🚀 Próba wysyłki na serwer...")
            } else {
                print("[AddVaultEntryView] Offline mode: Dane zapisane tylko lokalnie.")
            }
            
            dismiss()
        } catch {
            print("❌ Failed to encrypt and save entry: \(error)")
        }
    }
    
    private func generateAppleStylePassword(length: Int, symbols: Bool, numbers: Bool) -> String {
        var characters = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ"
        if numbers { characters += "23456789" }
        if symbols { characters += "!@#$%^&*_+=" }
        
        var result = ""
        for i in 0..<length {
            if i > 0 && (i + 1) % 7 == 0 {
                result.append("-")
            } else {
                result.append(characters.randomElement()!)
            }
        }
        return result
    }
}

struct EntryField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
            
            HStack {
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                            .submitLabel(submitLabel)
                            .onSubmit(onSubmit)
                    } else {
                        TextField("", text: $text)
                            .autocapitalization(.none)
                            .submitLabel(submitLabel)
                            .onSubmit(onSubmit)
                    }
                }
                .foregroundColor(.white)
                .font(.system(size: 14, design: .monospaced))
                
                if isSecure {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
        }
    }
}
