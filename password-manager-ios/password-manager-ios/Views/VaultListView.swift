import SwiftUI

enum SortOrder: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"

    var icon: String {
        switch self {
        case .newest: return "arrow.down.circle"
        case .oldest: return "arrow.up.circle"
        }
    }
}

struct VaultListView: View {
    @EnvironmentObject var vaultManager: LocalVaultManager
    @EnvironmentObject var authManager: AuthManager

    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingAddEntry = false
    @State private var sortOrder: SortOrder = .newest
    @State private var showSortMenu = false

    @FocusState private var isSearchFocused: Bool

    let builtinCategories = ["All", "Finance", "Social", "Work", "School", "Gaming", "Shopping"]

    var allCategories: [String] {
        let customCategories = vaultManager.entries
            .filter { $0.category == "Custom" }
            .compactMap { $0.customCategory }
            .filter { !$0.isEmpty }
        let unique = Array(Set(customCategories)).sorted()
        return builtinCategories + unique
    }

    var filteredEntries: [VaultEntry] {
        var result = vaultManager.entries

        if selectedCategory != "All" {
            result = result.filter {
                $0.effectiveCategory.localizedCaseInsensitiveCompare(selectedCategory) == .orderedSame
            }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText) ||
                $0.website.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sortowanie po lastModified
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"

        result.sort { a, b in
            let dateA = formatter.date(from: a.lastModified) ?? Date.distantPast
            let dateB = formatter.date(from: b.lastModified) ?? Date.distantPast
            return sortOrder == .newest ? dateA > dateB : dateA < dateB
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08)
                    .ignoresSafeArea()
                    .onTapGesture { isSearchFocused = false }

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Text("Vault")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()

                            // Sort button
                            Menu {
                                ForEach(SortOrder.allCases, id: \.self) { order in
                                    Button(action: { sortOrder = order }) {
                                        HStack {
                                            Text(order.rawValue)
                                            if sortOrder == order {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: sortOrder.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            }

                            Button(action: { showingAddEntry = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // Search
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                TextField("Search vault...", text: $searchText)
                                    .focused($isSearchFocused)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                            .cornerRadius(12)

                            if isSearchFocused {
                                Button("Cancel") {
                                    withAnimation { searchText = ""; isSearchFocused = false }
                                }
                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                .font(.system(size: 16, weight: .bold))
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 24)
                        .animation(.easeInOut, value: isSearchFocused)
                    }
                    .padding(.bottom, 12)

                    // Category bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allCategories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(selectedCategory == category
                                            ? Color(red: 0.51, green: 0.51, blue: 1)
                                            : Color(red: 0.16, green: 0.16, blue: 0.17))
                                        .foregroundColor(selectedCategory == category ? .black : .gray)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 16)

                    // Aktywny sort indicator
                    if !searchText.isEmpty || selectedCategory != "All" || sortOrder != .newest {
                        HStack(spacing: 8) {
                            if sortOrder != .newest {
                                FilterChip(label: sortOrder.rawValue, onRemove: { sortOrder = .newest })
                            }
                            if selectedCategory != "All" {
                                FilterChip(label: selectedCategory, onRemove: { selectedCategory = "All" })
                            }
                            Spacer()
                            Text("\(filteredEntries.count) entries")
                                .font(.system(size: 11)).foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    }

                    // List
                    if filteredEntries.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "lock.slash.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No entries found")
                                .font(.headline).foregroundColor(.gray)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { isSearchFocused = false }
                    } else {
                        List {
                            ForEach(filteredEntries) { entry in
                                NavigationLink(destination:
                                    PasswordDetailView(entry: entry, onDelete: {
                                        if let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                            vaultManager.entries.remove(at: index)
                                            vaultManager.saveToOfflineCache()
                                        }
                                    })
                                    .environmentObject(vaultManager)
                                    .environmentObject(authManager)
                                ) {
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

                                        // Mały badge kategorii
                                        Text(entry.effectiveCategory)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 6).padding(.vertical, 3)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(6)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Color.white.opacity(0.05))
                                .contextMenu {
                                    Button(action: {
                                        ClipboardManager.shared.copy(entry.username)
                                    }) {
                                        Label("Copy Username", systemImage: "person.fill")
                                    }
                                 
                                    Button(action: {
                                        if let decrypted = vaultManager.decryptEntry(
                                            entry: entry,
                                            masterKey: authManager.currentMasterKey
                                        ) {
                                            ClipboardManager.shared.copy(decrypted)
                                        }
                                    }) {
                                        Label("Copy Password", systemImage: "key.fill")
                                    }
                                 
                                    if !entry.website.isEmpty,
                                       let url = URL(string: entry.website.hasPrefix("http") ? entry.website : "https://\(entry.website)") {
                                        Button(action: {
                                            UIApplication.shared.open(url)
                                        }) {
                                            Label("Open Website", systemImage: "safari")
                                        }
                                    }
                                 
                                    Divider()
                                 
                                    Button(role: .destructive, action: {
                                        if let token = authManager.currentAPIToken,
                                           let index = vaultManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                            vaultManager.removeEntry(at: IndexSet(integer: index), token: token)
                                        }
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }

                            Color.clear.frame(height: 80)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddVaultEntryView()
                .environmentObject(vaultManager)
                .environmentObject(authManager)
        }
        .onAppear {
            if let token = authManager.currentAPIToken {
                    vaultManager.loadAndSyncVault(token: token)
            }
        }
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.1))
        .cornerRadius(8)
    }
}
