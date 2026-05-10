import SwiftUI

  

struct VaultListView: View {

    @StateObject private var vaultManager = LocalVaultManager()

    @State private var searchText = ""

    @State private var selectedCategory = "All"
    @State private var showingAddEntry = false

     

    let categories = ["All", "Finance", "Social", "Work", "Notes"]

    var filteredEntries: [VaultEntry] {
        var result = vaultManager.entries
        
        // Filtrowanie po kategorii
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Filtrowanie po tekście
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
     

    var body: some View {

        ZStack {

            // Ciemne tło aplikacji

            Color(red: 0.07, green: 0.07, blue: 0.08)

                .ignoresSafeArea()

             

            VStack(spacing: 0) {
                
                // --- NAGŁÓWEK ---
                
                HStack {
                    
                    HStack {
                        
                        RoundedRectangle(cornerRadius: 8)
                        
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.76))
                        
                            .frame(width: 32, height: 32)
                        
                            .overlay(Image(systemName: "lock.fill").foregroundColor(.black).font(.system(size: 14)))
                        
                        
                        
                        Text("The Vault")
                        
                            .font(.system(size: 20, weight: .bold))
                        
                            .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                        
                    }
                    
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                    
                        .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                    
                        .font(.system(size: 20))
                    
                }
                
                .padding(.horizontal, 24)
                
                .padding(.top, 16)
                
                
                
                // --- TYTUŁ ---
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text("SECURE REPOSITORY")
                    
                        .font(.system(size: 11, weight: .bold))
                    
                        .tracking(1.5)
                    
                        .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84).opacity(0.6))
                    
                    
                    
                    Text("Vault")
                    
                        .font(.system(size: 40, weight: .heavy))
                    
                        .foregroundColor(.white)
                    
                }
                
                .frame(maxWidth: .infinity, alignment: .leading)
                
                .padding(.horizontal, 24)
                
                .padding(.top, 24)
                
                
                
                // --- WYSZUKIWARKA ---
                
                HStack {
                    
                    Image(systemName: "magnifyingglass")
                    
                        .foregroundColor(Color.gray)
                    
                    TextField("Search passwords, keys, and notes", text: $searchText)
                    
                        .foregroundColor(.white)
                    
                }
                
                .padding()
                
                .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                
                .cornerRadius(12)
                
                .padding(.horizontal, 24)
                
                .padding(.top, 16)
                
                
                
                // --- KATEGORIE ---
                
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 12) {
                        
                        ForEach(categories, id: \.self) { category in
                            
                            Text(category)
                            
                                .font(.system(size: 14, weight: .semibold))
                            
                                .padding(.horizontal, 20)
                            
                                .padding(.vertical, 10)
                            
                                .background(selectedCategory == category ? Color(red: 0.51, green: 0.51, blue: 1) : Color(red: 0.16, green: 0.16, blue: 0.17))
                            
                                .foregroundColor(selectedCategory == category ? .white : Color(red: 0.76, green: 0.78, blue: 0.84))
                            
                                .cornerRadius(20)
                            
                                .onTapGesture {
                                    
                                    selectedCategory = category
                                    
                                }
                            
                        }
                        
                    }
                    
                    .padding(.horizontal, 24)
                    
                }
                
                .padding(.top, 20)
                
                
                
                // --- LISTA HASEŁ ---
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Używamy filteredEntries zamiast vaultManager.entries
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: PasswordDetailView(entry: entry, onDelete: {
                                vaultManager.entries.removeAll(where: { $0.id == entry.id })
                                    vaultManager.saveToOfflineCache()
                            })) {
                                VaultItemRow(entry: entry)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }

             

            // --- FLOATING ACTION BUTTON (+) ---

            VStack {

                Spacer()

                HStack {

                    Spacer()

                    Button(action: {

                        // Akcja dodawania hasła
                        showingAddEntry = true

                    }) {

                        Image(systemName: "plus")

                            .font(.system(size: 24, weight: .bold))

                            .foregroundColor(.white)

                            .frame(width: 60, height: 60)

                            .background(Color(red: 0.51, green: 0.51, blue: 1))

                            .cornerRadius(20)

                            .shadow(color: Color(red: 0.51, green: 0.51, blue: 1).opacity(0.4), radius: 15, y: 8)

                    }

                    .padding(.trailing, 24)

                    .padding(.bottom, 100)

                }

            }

             

            // --- BOTTOM TAB BAR ---

            VStack {

                Spacer()

                CustomTabBar()
                    .sheet(isPresented: $showingAddEntry) {
                        
                        AddVaultEntryView()
                            .environmentObject(vaultManager)
                    }

            }

        }

    }

}

  

// Komponent pojedynczego wiersza z hasłem

struct VaultItemRow: View {

    let entry: VaultEntry

     

    var body: some View {

        HStack(spacing: 16) {

            // Ikona

            ZStack {

                Color(red: 0.18, green: 0.18, blue: 0.19)

                    .frame(width: 50, height: 50)

                    .cornerRadius(12)

                Image(systemName: entry.iconName)

                    .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))

                    .font(.system(size: 20))

            }

             

            // Teksty

            VStack(alignment: .leading, spacing: 4) {

                Text(entry.title)

                    .font(.system(size: 16, weight: .bold))

                    .foregroundColor(.white)

                Text(entry.username)

                    .font(.system(size: 12, weight: .regular))

                    .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84).opacity(0.8))

            }

             

            Spacer()

             

            // Czas i kropki hasła

            VStack(alignment: .trailing, spacing: 6) {

                Text("••••")

                    .font(.system(size: 10, weight: .black))

                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))

                Text(entry.lastModified)

                    .font(.system(size: 9, weight: .bold))

                    .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84).opacity(0.5))

            }

        }

        .padding(16)

        .background(Color(red: 0.12, green: 0.12, blue: 0.13))

        .cornerRadius(16)

    }

}

  

// Customowy dolny pasek nawigacyjny

struct CustomTabBar: View {

    var body: some View {

        HStack {

            TabBarItem(icon: "lock.fill", text: "PASSWORDS", isSelected: true)

            Spacer()

            TabBarItem(icon: "star.fill", text: "FAVORITES", isSelected: false)

            Spacer()

            TabBarItem(icon: "shield.fill", text: "SECURITY", isSelected: false)

            Spacer()

            TabBarItem(icon: "gearshape.fill", text: "SETTINGS", isSelected: false)

        }

        .padding(.horizontal, 32)

        .padding(.vertical, 16)

        .background(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.95))

        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.05)), alignment: .top)

    }

}

  

struct TabBarItem: View {

    let icon: String

    let text: String

    let isSelected: Bool

     

    var body: some View {

        VStack(spacing: 6) {

            Image(systemName: icon)

                .font(.system(size: 20))

            Text(text)

                .font(.system(size: 9, weight: .bold))

        }

        .foregroundColor(isSelected ? Color(red: 0.51, green: 0.51, blue: 1) : Color(red: 0.76, green: 0.78, blue: 0.84).opacity(0.5))

        .frame(width: 65)

        .padding(.vertical, 8)

        .background(isSelected ? Color(red: 0.51, green: 0.51, blue: 1).opacity(0.15) : Color.clear)

        .cornerRadius(12)

    }

}

  

struct VaultListView_Previews: PreviewProvider {

    static var previews: some View {

        VaultListView()

    }

}
