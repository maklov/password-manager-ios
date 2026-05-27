import Foundation
import CryptoKit


class LocalVaultManager: ObservableObject {
    @Published var entries: [VaultEntry] = []
    
    private let cacheKey = "offline_vault_cache"
    
    // NOWOŚĆ: Dostęp do współdzielonej pamięci App Group
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.maklov.password-manager-ios")
    }
    
    init() {
        loadFromOfflineCache()
    }
    
    func addEntry(title: String, username: String, rawPassword: String, website: String, masterKey: SymmetricKey?) {
        guard let key = masterKey else {
            print("[LocalVaultManager] ❌ Brak klucza głównego! Nie mogę zaszyfrować danych.")
            return
        }
        
        do {
            let encryptedData = try CryptoService.encrypt(plaintext: rawPassword, using: key)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            let dateString = formatter.string(from: Date())
            
            let newEntry = VaultEntry(id: UUID().uuidString, title: title, username: username, website: website, ciphertext: encryptedData.ciphertext, nonce: encryptedData.nonce, category: "General", lastModified: dateString, iconName: "key.fill")
            entries.append(newEntry)
            saveToOfflineCache()
            print("[LocalVaultManager] 🔐 Hasło pomyślnie zaszyfrowane i dodane do sejfu.")
            
        } catch {
            print("[LocalVaultManager] ❌ Błąd szyfrowania: \(error)")
        }
    }
        
        func decryptEntry(entry: VaultEntry, masterKey: SymmetricKey?) -> String? {
            guard let key = masterKey else { return nil }
            
            do {
                return try CryptoService.decrypt(combinedCiphertext: entry.ciphertext, nonceBase64: entry.nonce, using: key)
            } catch {
                print("[LocalVaultManager] ❌ Nie udało się odszyfrować: \(error)")
                return nil
            }
        }
        
        func saveToOfflineCache() {
            do {
                let data = try JSONEncoder().encode(entries)
                // 1. Zapisujemy w głównej pamięci apki (Tego system nigdy nie usunie!)
                UserDefaults.standard.set(data, forKey: cacheKey)
                
                // 2. Wrzucamy kopię do tunelu dla Autofill
                sharedDefaults?.set(data, forKey: cacheKey)
                print("[LocalVaultManager] 📦 Saved to Standard & Shared cache.")
            } catch {
                print("[LocalVaultManager] ❌ Cache write error: \(error)")
            }
        }
        
        func loadFromOfflineCache() {
            // Zawsze czytamy z twardego dysku głównej aplikacji!
            guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
            do {
                let savedEntries = try JSONDecoder().decode([VaultEntry].self, from: data)
                self.entries = savedEntries
                print("[LocalVaultManager] 📦 Loaded \(entries.count) entries from STANDARD cache.")
            } catch {
                print("[LocalVaultManager] ❌ Cache read error: \(error)")
            }
        }
}
