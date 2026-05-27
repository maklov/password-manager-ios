import SwiftUI

struct PasswordDetailView: View {
    @State var entry: VaultEntry
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var vaultManager: LocalVaultManager
    
    @State private var isEditing: Bool = false
    @State private var editableUsername: String = ""
    @State private var editableWebsite: String = ""
    @State private var editablePassword: String = ""
    @State private var editableCategory: String = "General" // NOWE POLE DLA KATEGORII
    
    let categories = ["Finance", "Social", "Work", "Notes", "General"]
    
    @State private var showGenerator: Bool = true
    @State private var passwordLength: Double = 24
    @State private var useSymbols: Bool = true
    @State private var useNumbers: Bool = true
    
    @State private var showingGeneratorAlert: Bool = false
    @State private var generatedPasswordPlaceholder: String = ""
    
    private var decryptedVaultPassword: String {
        return vaultManager.decryptEntry(entry: entry, masterKey: authManager.currentMasterKey) ?? "Error decrypting"
    }
    
    var onDelete: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // --- HEADER ---
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
                            Text(entry.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("LAST MODIFIED \(entry.lastModified)")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)
                    
                    // --- SECURITY HEALTH ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Security Health")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(alignment: .bottom) {
                            let currentLength = isEditing ? editablePassword.count : decryptedVaultPassword.count
                            Text(currentLength >= 16 ? "Your password is exceptionally\nstrong." : "Consider generating a stronger\npassword.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(min(100, max(25, currentLength * 4)))%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.76), Color(red: 0.51, green: 0.51, blue: 1)], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 4)
                    }
                    .padding()
                    .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                    .cornerRadius(16)
                    
                    // --- DATA FIELDS & CATEGORY PICKER ---
                    VStack(spacing: 16) {
                        DetailRow(label: "USERNAME", value: $editableUsername, isEditing: isEditing, isCopyable: true)
                        DetailRow(label: "PASSWORD", value: $editablePassword, isEditing: isEditing, isCopyable: true, isSecure: true)
                        DetailRow(label: "WEBSITE", value: $editableWebsite, isEditing: isEditing, isCopyable: false, actionIcon: "arrow.up.right.square")
                        
                        // NOWA SEKCJA WYBORU KATEGORII W DETALACH
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            
                            HStack {
                                if isEditing {
                                    Picker("Select Category", selection: $editableCategory) {
                                        ForEach(categories, id: \.self) { cat in
                                            Text(cat).tag(cat)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color(red: 0.51, green: 0.51, blue: 1))
                                } else {
                                    Text(editableCategory.uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                            .cornerRadius(12)
                        }
                    }
                    
                    // --- PASSWORD GENERATOR ---
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation { showGenerator.toggle() }
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Generate Strong Password")
                                Spacer()
                                Image(systemName: showGenerator ? "chevron.down" : "chevron.right")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                        }
                        
                        if showGenerator {
                            VStack(spacing: 20) {
                                HStack {
                                    Image(systemName: "shield.fill")
                                    Text("Generator Settings")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Length")
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
                                }
                                
                                Button(action: {
                                    generatedPasswordPlaceholder = generateRandomPassword(length: Int(passwordLength), symbols: useSymbols, numbers: useNumbers)
                                    showingGeneratorAlert = true
                                }) {
                                    Text("Generate & Apply")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(red: 0.51, green: 0.51, blue: 1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                        }
                    }
                    .cornerRadius(16)
                    
                    if !isEditing {
                        Button(action: {
                            onDelete()
                            dismiss()
                        }) {
                            Label("Delete Entry", systemImage: "trash.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.red.opacity(0.8))
                                .padding(.vertical, 12)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color(red: 0.51, green: 0.51, blue: 1))
        .onAppear {
            setupEditableFields()
        }
        .alert("Replace current password?", isPresented: $showingGeneratorAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Replace", role: .destructive) {
                editablePassword = generatedPasswordPlaceholder
                isEditing = true
            }
        } message: {
            Text("New password: \(generatedPasswordPlaceholder)\n\nChanges will be saved permanently only after clicking 'Save' in the upper-right corner.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        isEditing = true
                    }
                }
                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                .font(.system(size: 16, weight: .bold))
            }
        }
    }
    
    private func setupEditableFields() {
        editableUsername = entry.username
        editableWebsite = entry.website
        editablePassword = decryptedVaultPassword
        editableCategory = entry.category.isEmpty ? "General" : entry.category
    }
    
    private func saveChanges() {
        guard let key = authManager.currentMasterKey else { return }
        
        if let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
            vaultManager.entries[index].username = editableUsername
            vaultManager.entries[index].website = editableWebsite
            vaultManager.entries[index].category = editableCategory // ZAPIS KATEGORII
            
            if editablePassword != decryptedVaultPassword {
                do {
                    let encrypted = try CryptoService.encrypt(plaintext: editablePassword, using: key)
                    vaultManager.entries[index].ciphertext = encrypted.ciphertext
                    vaultManager.entries[index].nonce = encrypted.nonce
                } catch {
                    print("[PasswordDetailView] ❌ Re-encryption failed: \(error)")
                }
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            vaultManager.entries[index].lastModified = formatter.string(from: Date()).uppercased()
            
            self.entry = vaultManager.entries[index]
        }
        
        vaultManager.saveToOfflineCache()
        isEditing = false
    }
    
    private func generateRandomPassword(length: Int, symbols: Bool, numbers: Bool) -> String {
        var letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        if numbers { letters += "0123456789" }
        if symbols { letters += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

// MARK: - DETAIL ROW COMPONENT (English Interface)
struct DetailRow: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    var isCopyable: Bool = false
    var isSecure: Bool = false
    var actionIcon: String? = nil
    
    @State private var showPlaintext = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
            
            HStack {
                if isEditing {
                    Group {
                        if isSecure && !showPlaintext {
                            SecureField("", text: $value)
                        } else {
                            TextField("", text: $value)
                                .autocapitalization(.none)
                        }
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 14, design: .monospaced))
                } else {
                    if isSecure && !showPlaintext {
                        Text(String(repeating: "•", count: max(1, value.count)))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.top, 4)
                    } else {
                        Text(value)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))
                    }
                }
                
                Spacer()
                
                if !isEditing {
                    HStack(spacing: 16) {
                        if isSecure {
                            Button(action: { showPlaintext.toggle() }) {
                                Image(systemName: showPlaintext ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if isCopyable {
                            Button(action: {
                                UIPasteboard.general.string = value
                            }) {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.8))
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let icon = actionIcon {
                            Button(action: {
                                if let url = URL(string: "https://\(value)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: icon)
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
        }
    }
}
