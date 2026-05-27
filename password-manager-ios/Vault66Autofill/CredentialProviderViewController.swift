import UIKit
import AuthenticationServices
import CryptoKit

class CredentialProviderViewController: ASCredentialProviderViewController {
    
    private let cacheKey = "offline_vault_cache"
    private let keychainKeyIdentifier = "com.ios-password-manager.masterkey" // Upewnij się, że pasuje do AuthManager
    
    // Definiujemy dostęp do wspólnego kontenera pamięci
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.maklov.password-manager-ios")
    }
    
    // Ta metoda jest wywoływana przez iOS, gdy użytkownik klika pole logowania w Safari
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        
        // 1. Pobieramy domenę aktualnej strony (np. github.com)
        let currentDomain = serviceIdentifiers.first?.identifier ?? ""
        print("[Autofill] 🌐 Request for domain: \(currentDomain)")
        
        // 2. Wczytujemy zaszyfrowaną bazę danych z App Group
        guard let data = sharedDefaults?.data(forKey: cacheKey),
              let entries = try? JSONDecoder().decode([VaultEntry].self, from: data) else {
            extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.noCredentialsFound.rawValue))
            return
        }
        
        // 3. Szukamy w naszym sejfie wpisu, który pasuje do domeny
        let matchedEntries = entries.filter { entry in
            currentDomain.localizedCaseInsensitiveContains(entry.website) ||
            entry.website.localizedCaseInsensitiveContains(currentDomain)
        }
        
        // 4. Jeśli nic nie znaleźliśmy, przerywamy
        guard let bestMatch = matchedEntries.first else {
            extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.noCredentialsFound.rawValue))
            return
        }
        
        // 5. Pobieramy Klucz Główny z bezpiecznego schowka (wygenerowany wcześniej przez Argon2 w aplikacji)
        // Dla uproszczenia w testach czytamy z UserDefaults grupy
        guard let keyData = sharedDefaults?.data(forKey: keychainKeyIdentifier) ?? UserDefaults.standard.data(forKey: keychainKeyIdentifier) else {
            extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCredentialVerificationRequired.rawValue))
            return
        }
        
        let masterKey = SymmetricKey(data: keyData)
        
        // 6. Odszyfrowujemy hasło przez AES-GCM przy użyciu pobranego klucza
        do {
            let decryptedPassword = try CryptoService.decrypt(combinedCiphertext: bestMatch.ciphertext, nonceBase64: bestMatch.nonce, using: masterKey)
            
            // 7. Tworzymy systemowy obiekt odpowiedzi i przekazujemy go bezpiecznie do iOS
            let credential = ASPasswordCredentialIdentity(
                serviceIdentifier: serviceIdentifiers.first!,
                user: bestMatch.username,
                recordIdentifier: bestMatch.id
            )
            
            // Podajemy dane logowania prosto do klawiatury iOS
            extensionContext.completeRegistrationRequest(withSelectedCredential: credential, password: decryptedPassword)
            print("[Autofill] ✅ Successfully autofilled credentials for \(bestMatch.username)")
            
        } catch {
            print("[Autofill] ❌ Decryption failed during autofill: \(error)")
            extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.credentialIdentityPreparationFailed.rawValue))
        }
    }
}
