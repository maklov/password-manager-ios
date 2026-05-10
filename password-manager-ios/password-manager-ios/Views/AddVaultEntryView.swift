import SwiftUI

struct AddVaultEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vaultManager: LocalVaultManager
    
    // Pola formularza
    @State private var title: String = ""
    @State private var username: String = ""
    @State private var website: String = ""
    @State private var plaintextPassword: String = "" // Na razie wpisujemy jawnie
    @State private var selectedCategory: String = "Social"
    
    let categories = ["All", "Finance", "Social", "Work", "Notes"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pola wprowadzania danych
                        VStack(spacing: 16) {
                            EntryField(label: "TITLE (e.g. GitHub)", text: $title)
                            EntryField(label: "USERNAME OR EMAIL", text: $username)
                            EntryField(label: "WEBSITE (e.g. github.com)", text: $website)
                            EntryField(label: "PASSWORD", text: $plaintextPassword, isSecure: true)
                        }
                        // Wybór kategorii
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories.filter { $0 != "All" }, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                            // Kolorowanie segmentów to zawiła sprawa w SwiftUI, ale ten podstawowy zadziała
                        }
                        .padding(.top, 8)
                        
                        // Przycisk Zapisu
                        Button(action: {
                            // 1. W PRZYSZŁOŚCI: Tutaj zaszyfrujemy plaintextPassword przez AES!
                            // 2. Tworzymy nowy obiekt
                            let newEntry = VaultEntry(
                                title: title.isEmpty ? "Untitled" : title,
                                username: username,
                                website: website,
                                ciphertext: plaintextPassword, // Na razie trzymamy czyste hasło dla testów UI
                                iv: "dummy_iv",
                                category: selectedCategory,
                                lastModified: "JUST NOW",
                                iconName: "key.fill" // Domyślna ikona
                            )
                            
                            // 3. Zapisujemy do RAM i Offline
                            vaultManager.entries.append(newEntry)
                            vaultManager.saveToOfflineCache()
                            
                            // 4. Zamykamy ekran
                            dismiss()
                        }) {
                            Text("Save to Vault")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.51, green: 0.51, blue: 1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 24)
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
                // Zmiana koloru tytułu nawigacji
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.08), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

    // Pomocnicze pole tekstowe
struct EntryField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .autocapitalization(.none)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
        }
    }
}
