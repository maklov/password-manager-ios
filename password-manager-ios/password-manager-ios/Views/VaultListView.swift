import SwiftUI

struct VaultListView: View {
    @StateObject private var vaultManager = LocalVaultManager()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingAddEntry = false

    let categories = ["All", "Finance", "Social", "Work", "Notes"]

    // POPRAWIONE FILTROWANIE: Bezpieczne dopasowanie kategorii i tekstu
    var filteredEntries: [VaultEntry] {
        var result = vaultManager.entries
        
        // 1. Filtrowanie po kategorii (case-insensitive)
        if selectedCategory != "All" {
            result = result.filter { $0.category.localizedCaseInsensitiveCompare(selectedCategory) == .orderedSame }
        }
        
        // 2. Filtrowanie po tekście wyszukiwarki
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText) ||
                $0.website.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // --- SEARCH BAR & HEADER ---
                    VStack(spacing: 16) {
                        HStack {
                            Text("Vault")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { showingAddEntry = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search vault...", text: $searchText)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 12)
                    
                    // --- CATEGORY SELECTOR ---
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color(red: 0.51, green: 0.51, blue: 1) : Color(red: 0.16, green: 0.16, blue: 0.17))
                                        .foregroundColor(selectedCategory == category ? .black : .gray)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 16)
                    
                    // --- LIST VIEW ---
                    if filteredEntries.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "lock.slash.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No entries found")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredEntries) { entry in
                                NavigationLink(destination: PasswordDetailView(entry: entry, onDelete: {
                                    if let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                        vaultManager.entries.remove(at: index)
                                        vaultManager.saveToOfflineCache()
                                    }
                                })) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.05))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: entry.iconName)
                                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.title)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(entry.username)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Color.white.opacity(0.05))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddVaultEntryView()
        }
        .onAppear {
            vaultManager.loadFromOfflineCache()
        }
    }
}

struct VaultListView_Previews: PreviewProvider {

    static var previews: some View {

        VaultListView()
            .environmentObject(LocalVaultManager()) // <-- MUSZĄ BYĆ NAWIASY
            .environmentObject(AuthManager())

    }

}
