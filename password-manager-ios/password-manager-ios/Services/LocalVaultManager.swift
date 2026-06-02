import Foundation
import CryptoKit

@MainActor
final class LocalVaultManager: ObservableObject {
    @Published var entries: [VaultEntry] = []

    private var cacheKey: String {
        let email = UserDefaults.standard.string(forKey: "last_logged_email") ?? "default_user"
        return "vault_cache_\(email)"
    }

    private var pendingKey: String {
        let email = UserDefaults.standard.string(forKey: "last_logged_email") ?? "default_user"
        return "vault_pending_\(email)"
    }

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.maklov.password-manager-ios")
    }

    init() { loadFromOfflineCache() }

    // MARK: - Sync z serwerem
    func loadAndSyncVault(token: String) {
        Task {
            let result = await APIService.shared.fetchVault(token: token)
            DispatchQueue.main.async {
                switch result {
                case .success(let serverEntries):
                    // Scal wpisy serwera z pending queue — pending ma priorytet
                    let pending = self.loadPendingQueue()
                    if pending.isEmpty {
                        self.entries = serverEntries
                    } else {
                        // Zachowaj pending wpisy których nie ma na serwerze
                        let serverIds = Set(serverEntries.compactMap { $0.serverId })
                        let pendingOnly = pending.filter { $0.serverId == nil || !serverIds.contains($0.serverId!) }
                        self.entries = serverEntries + pendingOnly
                        print("[VaultManager] 🔀 Scalono \(serverEntries.count) z serwera + \(pendingOnly.count) pending")
                    }
                    self.saveToOfflineCache()
                case .failure(let error):
                    print("[VaultManager] ⚠️ Błąd serwera: \(error). Używam cache.")
                    self.loadFromOfflineCache()
                }
            }
        }
    }

    func pushChangesToServer(entry: VaultEntry, token: String) {
        Task {
            let result = await APIService.shared.syncVaultToServer(entry: entry, token: token)
            switch result {
            case .success(let serverId):
                // Sukces — przypisz serverId i usuń z pending queue
                if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                    self.entries[index].serverId = serverId
                    self.saveToOfflineCache()
                }
                self.removeFromPendingQueue(entryId: entry.id)
                print("[VaultManager] ☁️ Wysłano na serwer: \(entry.title) (serverId: \(serverId))")

            case .failure(let error):
                if case .offline = error {
                    // Brak sieci — zapisz do pending queue
                    self.saveToPendingQueue(entry)
                    print("[VaultManager] 📦 Brak sieci — wpis w pending queue: \(entry.title)")
                } else {
                    print("[VaultManager] ⚠️ Błąd wysyłki: \(error)")
                }
            }
        }
    }

    func updateEntryOnServer(entry: VaultEntry, token: String) {
        Task {
            let result = await APIService.shared.updateEntryOnServer(entry: entry, token: token)
            switch result {
            case .success:
                print("[VaultManager] ✏️ Zaktualizowano: \(entry.title)")
            case .failure(let error):
                print("[VaultManager] ⚠️ Błąd aktualizacji: \(error)")
            }
        }
    }

    // MARK: - Pending Queue
    private func saveToPendingQueue(_ entry: VaultEntry) {
        var pending = loadPendingQueue()
        // Nie dodawaj duplikatów
        if !pending.contains(where: { $0.id == entry.id }) {
            pending.append(entry)
        }
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: pendingKey)
            print("[VaultManager] 📦 Pending queue: \(pending.count) wpisów")
        }
    }

    private func removeFromPendingQueue(entryId: String) {
        var pending = loadPendingQueue()
        pending.removeAll { $0.id == entryId }
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    func loadPendingQueue() -> [VaultEntry] {
        guard let data = UserDefaults.standard.data(forKey: pendingKey),
              let entries = try? JSONDecoder().decode([VaultEntry].self, from: data) else { return [] }
        return entries
    }

    func clearPendingQueue() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }

    // Wywoływane gdy sieć wraca — wysyła wszystkie pending wpisy
    func flushPendingQueue(token: String) {
        let pending = loadPendingQueue()
        guard !pending.isEmpty else { return }

        print("[VaultManager] 📤 Flush pending queue: \(pending.count) wpisów...")

        Task {
            for entry in pending {
                let result = await APIService.shared.syncVaultToServer(entry: entry, token: token)
                switch result {
                case .success(let serverId):
                    if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                        self.entries[index].serverId = serverId
                    }
                    self.removeFromPendingQueue(entryId: entry.id)
                    print("[VaultManager] ✅ Pending wysłany: \(entry.title) → serverId: \(serverId)")
                case .failure(let error):
                    print("[VaultManager] ⚠️ Pending nadal offline: \(entry.title) — \(error)")
                    // Zostaje w kolejce — spróbujemy następnym razem
                }
            }
            self.saveToOfflineCache()

            let remaining = self.loadPendingQueue().count
            if remaining == 0 {
                print("[VaultManager] ✅ Pending queue wyczyszczona — wszystko na serwerze")
            } else {
                print("[VaultManager] ⚠️ Pozostało \(remaining) wpisów w pending queue")
            }
        }
    }

    // MARK: - Add Entry
    func addEntry(
        title: String,
        username: String,
        rawPassword: String,
        website: String,
        notes: String,
        category: String,
        customCategory: String,
        masterKey: SymmetricKey?,
        token: String
    ) {
        guard let key = masterKey else { return }

        do {
            let encryptedPassword = try CryptoService.encrypt(plaintext: rawPassword, using: key)

            var notesCiphertext: String? = nil
            var notesNonce: String? = nil
            if !notes.isEmpty {
                let encryptedNotes = try CryptoService.encrypt(plaintext: notes, using: key)
                notesCiphertext = encryptedNotes.ciphertext
                notesNonce = encryptedNotes.nonce
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            let dateString = formatter.string(from: Date()).uppercased()

            let newEntry = VaultEntry(
                id: UUID().uuidString,
                serverId: nil,
                title: title,
                username: username,
                website: website,
                ciphertext: encryptedPassword.ciphertext,
                nonce: encryptedPassword.nonce,
                notesCiphertext: notesCiphertext,
                notesNonce: notesNonce,
                category: category,
                customCategory: customCategory.isEmpty ? nil : customCategory,
                lastModified: dateString,
                iconName: "key.fill"
            )

            self.entries.append(newEntry)
            saveToOfflineCache()

            if !token.isEmpty {
                pushChangesToServer(entry: newEntry, token: token)
            } else {
                // Brak tokena — od razu do pending queue
                saveToPendingQueue(newEntry)
                print("[VaultManager] 📦 Brak tokena — wpis w pending queue: \(title)")
            }
        } catch {
            print("[LocalVaultManager] ❌ Błąd szyfrowania: \(error)")
        }
    }

    // MARK: - Decrypt
    func decryptEntry(entry: VaultEntry, masterKey: SymmetricKey?) -> String? {
        guard let key = masterKey else { return nil }
        return try? CryptoService.decrypt(combinedCiphertext: entry.ciphertext, nonceBase64: entry.nonce, using: key)
    }

    func decryptNotes(entry: VaultEntry, masterKey: SymmetricKey?) -> String? {
        guard let key = masterKey,
              let ciphertext = entry.notesCiphertext,
              let nonce = entry.notesNonce else { return nil }
        return try? CryptoService.decrypt(combinedCiphertext: ciphertext, nonceBase64: nonce, using: key)
    }

    // MARK: - Remove
    func removeEntry(at offsets: IndexSet, token: String) {
        let entriesToDelete = offsets.map { entries[$0] }
        self.entries.remove(atOffsets: offsets)
        self.saveToOfflineCache()

        // Usuń też z pending queue jeśli tam były
        for entry in entriesToDelete {
            removeFromPendingQueue(entryId: entry.id)
        }

        Task {
            for entry in entriesToDelete {
                let result = await APIService.shared.deleteEntryFromServer(entry: entry, token: token)
                switch result {
                case .success: print("[VaultManager] 🗑️ Usunięto: \(entry.title)")
                case .failure(let error): print("[VaultManager] ⚠️ Błąd usuwania: \(error)")
                }
            }
        }
    }

    // MARK: - Cache
    func saveToOfflineCache() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: cacheKey)
            sharedDefaults?.set(data, forKey: cacheKey)
        } catch {
            print("[LocalVaultManager] ❌ Cache write error: \(error)")
        }
    }

    func loadFromOfflineCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            self.entries = []
            return
        }
        do {
            self.entries = try JSONDecoder().decode([VaultEntry].self, from: data)
        } catch {
            print("[LocalVaultManager] ❌ Cache read error: \(error)")
        }
    }
}
