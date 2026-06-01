import Foundation
import CryptoKit

@MainActor
final class LocalVaultManager: ObservableObject {
    @Published var entries: [VaultEntry] = []
    
    // Klucz teraz zależy od użytkownika, aby konta nie współdzieliły danych
    private var cacheKey: String {
        let email = UserDefaults.standard.string(forKey: "last_logged_email") ?? "default_user"
        return "vault_cache_\(email)"
    }
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.maklov.password-manager-ios")
    }
    
    init() {
        // Przy starcie ładujemy lokalny cache, ale w trakcie życia aplikacji
        // wywołujemy loadAndSyncVault, który go nadpisze danymi z serwera.
        loadFromOfflineCache()
    }
    
    // GŁÓWNA METODA: Priorytet serwera
    func loadAndSyncVault(token: String) {
        Task {
            print("[VaultManager] 🌐 Pobieranie danych z serwera...")
            let result = await APIService.shared.fetchVault(token: token)
            
            DispatchQueue.main.async {
                switch result {
                case .success(let serverEntries):
                    self.entries = serverEntries
                    self.saveToOfflineCache() // Nadpisujemy cache świeżymi danymi z bazy
                    print("[VaultManager] 🔥 Dane zsynchronizowane z serwerem. Liczba: \(serverEntries.count)")
                case .failure(let error):
                    print("[VaultManager] ⚠️ Błąd serwera/sieci: \(error). Używam cache.")
                    self.loadFromOfflineCache() // Tylko jeśli serwer zawiedzie, bierzemy cache
                }
            }
        }
    }
    
    func pushChangesToServer(entry: VaultEntry, token: String) {
        Task {
            print("[VaultManager] 📤 Wysyłam do API...")
            let result = await APIService.shared.syncVaultToServer(entry: entry, token: token)
            
            switch result {
            case .success(let serverId):
                // Zapisz serverId z powrotem do lokalnego wpisu
                if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                    self.entries[index].serverId = serverId
                    self.saveToOfflineCache()
                    print("[VaultManager] ☁️ serverId \(serverId) zapisany lokalnie.")
                }
            case .failure(let error):
                print("[VaultManager] ⚠️ Błąd wysyłki: \(error)")
            }
        }
    }

    func addEntry(title: String, username: String, rawPassword: String, website: String, masterKey: SymmetricKey?, token: String) {
        guard let key = masterKey else { return }
        
        do {
            let encryptedData = try CryptoService.encrypt(plaintext: rawPassword, using: key)
            let newEntry = VaultEntry(id: UUID().uuidString, title: title, username: username, website: website, ciphertext: encryptedData.ciphertext, nonce: encryptedData.nonce, category: "General", lastModified: "2026-06-01", iconName: "key.fill")
            
            // Dodajemy lokalnie i zapisujemy do cache danego użytkownika
            self.entries.append(newEntry)
            saveToOfflineCache()
            
            // Próbujemy wysłać na serwer
            if !token.isEmpty {
                pushChangesToServer(entry: newEntry, token: token)

                } else {
                    print("[LocalVaultManager] ⚠️ Token jest pusty - dodano tylko lokalnie.")
                }
            
        } catch {
            print("[LocalVaultManager] ❌ Błąd szyfrowania: \(error)")
        }
    }
    
    func saveToOfflineCache() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: cacheKey)
            sharedDefaults?.set(data, forKey: cacheKey)
            print("[LocalVaultManager] 📦 Saved to cache: \(cacheKey)")
        } catch {
            print("[LocalVaultManager] ❌ Cache write error: \(error)")
        }
    }
    
    func loadFromOfflineCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            self.entries = [] // Jeśli nie ma cache, czyścimy listę dla nowego konta
            return
        }
        do {
            let savedEntries = try JSONDecoder().decode([VaultEntry].self, from: data)
            self.entries = savedEntries
            print("[LocalVaultManager] 📦 Loaded \(entries.count) entries from \(cacheKey)")
        } catch {
            print("[LocalVaultManager] ❌ Cache read error: \(error)")
        }
    }
    func decryptEntry(entry: VaultEntry, masterKey: SymmetricKey?) -> String? {
        guard let key = masterKey else {
            print("[LocalVaultManager] ❌ Brak klucza do odszyfrowania")
            return nil
        }
        
        do {
            // CryptoService.decrypt musi być dostępna w całym projekcie
            return try CryptoService.decrypt(combinedCiphertext: entry.ciphertext, nonceBase64: entry.nonce, using: key)
        } catch {
            print("[LocalVaultManager] ❌ Błąd deszyfrowania: \(error)")
            return nil
        }
    }
    func removeEntry(at offsets: IndexSet, token: String) {
        let entriesToDelete = offsets.map { entries[$0] }
        
        self.entries.remove(atOffsets: offsets)
        self.saveToOfflineCache()
        
        Task {
            for entry in entriesToDelete {
                let result = await APIService.shared.deleteEntryFromServer(entry: entry, token: token)
                switch result {
                case .success:
                    print("[VaultManager] 🗑️ Usunięto z serwera: \(entry.title)")
                case .failure(let error):
                    print("[VaultManager] ⚠️ Błąd usuwania z serwera: \(error)")
                }
            }
        }
    }
    func updateEntryOnServer(entry: VaultEntry, token: String) {
        Task {
            let result = await APIService.shared.updateEntryOnServer(entry: entry, token: token)
            switch result {
            case .success:
                print("[VaultManager] ✏️ Zaktualizowano wpis na serwerze: \(entry.title)")
            case .failure(let error):
                print("[VaultManager] ⚠️ Błąd aktualizacji: \(error)")
            }
        }
    }
}
