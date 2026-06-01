import Foundation
import CryptoKit

@MainActor
final class LocalVaultManager: ObservableObject {
    @Published var entries: [VaultEntry] = []

    private var cacheKey: String {
        let email = UserDefaults.standard.string(forKey: "last_logged_email") ?? "default_user"
        return "vault_cache_\(email)"
    }

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.maklov.password-manager-ios")
    }

    init() { loadFromOfflineCache() }

    // MARK: - Sync
    func loadAndSyncVault(token: String) {
        Task {
            let result = await APIService.shared.fetchVault(token: token)
            DispatchQueue.main.async {
                switch result {
                case .success(let serverEntries):
                    self.entries = serverEntries
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
                if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                    self.entries[index].serverId = serverId
                    self.saveToOfflineCache()
                }
            case .failure(let error):
                print("[VaultManager] ⚠️ Błąd wysyłki: \(error)")
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

            // Szyfruj notes jeśli nie puste
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
