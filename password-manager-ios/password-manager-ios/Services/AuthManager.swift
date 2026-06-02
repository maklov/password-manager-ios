import Foundation
import LocalAuthentication
import CryptoKit
import Security

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isBiometricAvailable: Bool = false

    private(set) var currentMasterKey: SymmetricKey?
    @Published var loginError: String? = nil
    @Published var currentAPIToken: String? = nil
    @Published var sessionExpired: Bool = false

    // Referencja do vaultManager — ustawiana z zewnątrz po inicjalizacji
    var vaultManager: LocalVaultManager? = nil

    private let keychainIdentifier = "com.ios-password-manager.masterkey"

    init() {
        checkBiometricAvailability()
    }

    private func getTokenKey(for email: String) -> String {
        return "api_token_\(email.lowercased())"
    }

    func refreshSessionAfterBiometrics() {
        guard let email = UserDefaults.standard.string(forKey: "last_logged_email") else { return }

        guard let savedToken = KeychainService.load(key: getTokenKey(for: email)) else {
            print("[AuthManager] ⚠️ Brak tokena w Keychainie dla: \(email)")
            return
        }

        self.currentAPIToken = savedToken

        Task {
            let result = await APIService.shared.fetchVault(token: savedToken)
            DispatchQueue.main.async {
                if case .failure(let error) = result, case .unauthorized = error {
                    print("[AuthManager] 🔒 Token wygasł. Wymagane ponowne logowanie.")
                    self.isAuthenticated = false
                    self.currentMasterKey = nil
                    self.currentAPIToken = nil
                    self.sessionExpired = true
                } else {
                    // Token OK — flush pending queue
                    self.vaultManager?.flushPendingQueue(token: savedToken)
                }
            }
        }
    }

    func loginWith(masterPassword: String, email: String) {
        let dummySalt = Data("extrasecretshii".utf8)

        do {
            let key = try CryptoService.deriveKey(masterPassword: masterPassword, salt: dummySalt)

            Task {
                let result = await APIService.shared.login(email: email, password: masterPassword)

                DispatchQueue.main.async {
                    switch result {
                    case .success(let token):
                        self.currentMasterKey = key
                        self.saveKeyToKeychain(key: key)
                        UserDefaults.standard.set(email, forKey: "last_logged_email")
                        self.currentAPIToken = token
                        KeychainService.save(key: self.getTokenKey(for: email), value: token)
                        self.isAuthenticated = true
                        print("[AuthManager] ☁️ Zalogowano pomyślnie.")

                        // Flush pending queue — wyślij wpisy dodane offline
                        self.vaultManager?.flushPendingQueue(token: token)

                    case .failure(let error):
                        self.loginError = "Incorrect email or password"
                        print("[AuthManager] ❌ Błąd logowania: \(error)")
                    }
                }
            }
        } catch {
            self.loginError = "An error occurred. Please try again."
            print("[AuthManager] ❌ Błąd klucza: \(error)")
        }
    }

    func loginWithFaceID() {
        let context = LAContext()
        guard let email = UserDefaults.standard.string(forKey: "last_logged_email") else { return }

        let hasToken = KeychainService.load(key: getTokenKey(for: email)) != nil
        guard hasToken else {
            print("[AuthManager] ❌ Face ID zablokowane: brak zapisanego tokena sesji.")
            return
        }
        guard UserDefaults.standard.bool(forKey: "biometric_unlock_enabled") else { return }

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Odblokuj sejf") { success, _ in
                DispatchQueue.main.async {
                    if success, let retrievedKey = self.getKeyFromKeychain() {
                        self.currentMasterKey = retrievedKey
                        self.refreshSessionAfterBiometrics() // flush pending też tu
                        self.isAuthenticated = true
                        print("[AuthManager] 🔓 Zalogowano przez Face ID!")
                    }
                }
            }
        }
    }

    func logout() {
        self.isAuthenticated = false
        self.currentMasterKey = nil
        self.currentAPIToken = nil
        print("[AuthManager] 🔒 Wylogowano!")
    }

    private func checkBiometricAvailability() {
        self.isBiometricAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    private func saveKeyToKeychain(key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        UserDefaults.standard.set(keyData, forKey: keychainIdentifier)
    }

    private func getKeyFromKeychain() -> SymmetricKey? {
        guard let keyData = UserDefaults.standard.data(forKey: keychainIdentifier) else { return nil }
        return SymmetricKey(data: keyData)
    }
}
