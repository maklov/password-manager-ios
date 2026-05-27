import Foundation
import LocalAuthentication
import CryptoKit
import Security

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isBiometricAvailable: Bool = false
    
    private(set) var currentMasterKey: SymmetricKey?
    private let keychainIdentifier = "com.ios-password-manager.masterkey"
    
    init () {
        checkBiometricAvailability()
    }
    
    func loginWith(masterPassword: String) {
        let dummySalt = Data("extrasecretshii".utf8)
        
        do
        {
            let key = try CryptoService.deriveKey(masterPassword: masterPassword, salt: dummySalt)
            
            self.currentMasterKey = key
            
            saveKeyToKeychain(key: key)
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }
        catch
        {
            print("[AuthManager] ❌ Błąd logowania hasłem: \(error)")
        }
    }
    
    func loginWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Odblokuj dostęp do swojego sejfu haseł"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {success, authError in
                DispatchQueue.main.async {
                    if success {
                        if let retrievedKey = self.getKeyFromKeychain() {
                            self.currentMasterKey = retrievedKey
                            self.isAuthenticated = true
                            print("[AuthManager] 🔓 Zalogowano przez Face ID!")
                        }
                        else {
                            print("[AuthManager] ⚠️ Face ID poprawne, ale brak klucza w pamięci. Zaloguj się najpierw hasłem.")
                        }
                    }
                    else {
                        print("[AuthManager] ❌ Błąd autoryzacji Face ID: \(authError?.localizedDescription ?? "Nieokreślony błąd")")
                    }
                }
            }
        }
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentMasterKey = nil
            print("[AuthManager] 🔒 Wylogowano!")
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.isBiometricAvailable = true
        } else {
            self.isBiometricAvailable = false
        }
    }
    
    private func saveKeyToKeychain(key: SymmetricKey) {
        let keyData = key.withUnsafeBytes {Data ($0)}
        UserDefaults.standard.set(keyData, forKey: keychainIdentifier)
        UserDefaults(suiteName: "group.maklov.password-manager-ios")?.set(keyData, forKey: keychainIdentifier)
    }
    
    private func getKeyFromKeychain() -> SymmetricKey? {
        guard let keyData = UserDefaults.standard.data(forKey: keychainIdentifier) else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
}


    
    
