import SwiftUI

enum FocusField: Hashable {
    case title, website, username, password, notes, customCategory
}

let builtinCategories = ["Finance", "Social", "Work", "School", "Gaming", "Shopping"]

struct AddVaultEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vaultManager: LocalVaultManager
    @EnvironmentObject var authManager: AuthManager

    @State private var title: String = ""
    @State private var username: String = ""
    @State private var website: String = ""
    @State private var plaintextPassword: String = ""
    @State private var notes: String = ""
    @State private var selectedCategory: String = "Social"
    @State private var customCategoryInput: String = ""

    @FocusState private var focusedField: FocusField?

    @State private var showGenerator: Bool = false
    @State private var passwordLength: Double = 20
    @State private var useSymbols: Bool = true
    @State private var useNumbers: Bool = true

    // Builtin + istniejące custom z vaultManager
    var allCategories: [String] {
        let existing = vaultManager.entries
            .filter { $0.category == "Custom" }
            .compactMap { $0.customCategory }
            .filter { !$0.isEmpty }
        let unique = Array(Set(existing)).sorted()
        return builtinCategories + unique + ["Custom"]
    }

    var canSave: Bool {
        !title.isEmpty && !plaintextPassword.isEmpty &&
        (selectedCategory != "Custom" || !customCategoryInput.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Pola główne
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

                            EntryField(label: "PASSWORD", text: $plaintextPassword, isSecure: true, submitLabel: .next) {
                                focusedField = .notes
                            }
                            .focused($focusedField, equals: .password)
                        }

                        // Generator
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
                                            Text("Length").font(.system(size: 13)).foregroundColor(.white)
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
                                        Toggle("Symbols", isOn: $useSymbols).toggleStyle(.button).tint(Color(red: 0.51, green: 0.51, blue: 1))
                                        Toggle("Numbers", isOn: $useNumbers).toggleStyle(.button).tint(Color(red: 0.51, green: 0.51, blue: 1))
                                        Spacer()
                                    }
                                    Button(action: {
                                        plaintextPassword = generatePassword(length: Int(passwordLength), symbols: useSymbols, numbers: useNumbers)
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
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("NOTES")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(notes.count)/250")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(notes.count > 220 ? .orange : .gray)
                            }

                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add secure notes...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 8).padding(.leading, 4)
                                }
                                TextEditor(text: $notes)
                                    .focused($focusedField, equals: .notes)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80, maxHeight: 120)
                                    .onChange(of: notes) { value in
                                        if value.count > 250 { notes = String(value.prefix(250)) }
                                    }
                            }
                            .padding(12)
                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                            .cornerRadius(12)

                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill").font(.system(size: 10))
                                Text("Notes are encrypted with AES-GCM").font(.system(size: 11))
                            }
                            .foregroundColor(.gray.opacity(0.6))
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 8
                            ) {
                                ForEach(allCategories, id: \.self) { cat in
                                    Button(action: {
                                        selectedCategory = cat
                                        // Jeśli wybrano istniejącą custom kategorię — wstaw jej nazwę
                                        if !builtinCategories.contains(cat) && cat != "Custom" {
                                            customCategoryInput = cat
                                        }
                                    }) {
                                        Text(cat == "Custom" ? "✏️ New" : cat)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedCategory == cat
                                                ? Color(red: 0.51, green: 0.51, blue: 1)
                                                : Color(red: 0.16, green: 0.16, blue: 0.17))
                                            .foregroundColor(selectedCategory == cat ? .black : .gray)
                                            .cornerRadius(10)
                                    }
                                }
                            }

                            // Pole custom kategorii — pojawia się gdy wybrano "Custom" lub nową
                            if selectedCategory == "Custom" {
                                EntryField(
                                    label: "CUSTOM CATEGORY NAME",
                                    text: $customCategoryInput,
                                    submitLabel: .done
                                ) { focusedField = nil }
                                .focused($focusedField, equals: .customCategory)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedCategory)

                        // Save
                        Button(action: saveNewEntry) {
                            Text("Save to Vault")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(canSave ? Color(red: 0.08, green: 0.08, blue: 0.4) : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSave
                                    ? Color(red: 0.51, green: 0.51, blue: 1)
                                    : Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .animation(.easeInOut(duration: 0.2), value: canSave)
                        }
                        .disabled(!canSave)
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.gray)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { focusedField = .title }
        }
    }

    private func saveNewEntry() {
        guard let masterKey = authManager.currentMasterKey else { return }
        let token = authManager.currentAPIToken ?? ""

        // Dla istniejącej custom kategorii — category = "Custom", customCategory = nazwa
        let finalCategory: String
        let finalCustom: String
        if builtinCategories.contains(selectedCategory) {
            finalCategory = selectedCategory
            finalCustom = ""
        } else if selectedCategory == "Custom" {
            finalCategory = "Custom"
            finalCustom = customCategoryInput
        } else {
            // Kliknięto istniejącą custom kategorię
            finalCategory = "Custom"
            finalCustom = selectedCategory
        }

        vaultManager.addEntry(
            title: title,
            username: username,
            rawPassword: plaintextPassword,
            website: website,
            notes: notes,
            category: finalCategory,
            customCategory: finalCustom,
            masterKey: masterKey,
            token: token
        )
        dismiss()
    }

    private func generatePassword(length: Int, symbols: Bool, numbers: Bool) -> String {
        var chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ"
        if numbers { chars += "23456789" }
        if symbols { chars += "!@#$%^&*_+=" }
        var result = ""
        for i in 0..<length {
            if i > 0 && (i + 1) % 7 == 0 { result.append("-") }
            else { result.append(chars.randomElement()!) }
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
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text).submitLabel(submitLabel).onSubmit(onSubmit)
                    } else {
                        TextField("", text: $text).textInputAutocapitalization(.never).submitLabel(submitLabel).onSubmit(onSubmit)
                    }

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
