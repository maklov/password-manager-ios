import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var autoLockManager: AutoLockManager

    @State private var passwordInput: String = ""
    @State private var loginError: String? = nil
    @State private var shakeAttempts: CGFloat = 0
    @State private var isVerifying: Bool = false

    @AppStorage("last_logged_email") private var savedEmail: String = ""
    @AppStorage("biometric_unlock_enabled") private var biometricEnabled: Bool = false

    var body: some View {
        ZStack {
            // Rozmyte tło — sugestia że vault jest "za" ekranem
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            // Dekoracyjne kółka w tle
            ZStack {
                Circle()
                    .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.06))
                    .frame(width: 350, height: 350)
                    .offset(x: -80, y: -200)
                    .blur(radius: 40)

                Circle()
                    .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.04))
                    .frame(width: 250, height: 250)
                    .offset(x: 100, y: 200)
                    .blur(radius: 30)
            }

            VStack(spacing: 32) {
                Spacer()

                // Ikona kłódki
                ZStack {
                    Circle()
                        .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.12))
                        .frame(width: 96, height: 96)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))
                }

                VStack(spacing: 8) {
                    Text("Vault Locked")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)

                    Text(savedEmail.isEmpty ? "Enter your master password" : savedEmail)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                // Pole hasła
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        SecureField("Master password", text: $passwordInput)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        loginError != nil ? Color.red.opacity(0.6) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .onSubmit { verifyPassword() }

                        if let error = loginError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(error)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: loginError)

                    // Przycisk odblokowania
                    Button(action: verifyPassword) {
                        HStack {
                            if isVerifying {
                                ProgressView().tint(.black).scaleEffect(0.8)
                            } else {
                                Text("Unlock")
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.51, green: 0.51, blue: 1))
                        .cornerRadius(12)
                    }
                    .disabled(passwordInput.isEmpty || isVerifying)
                    .modifier(ShakeEffect(animatableData: shakeAttempts))
                }
                .padding(.horizontal, 32)

                // Face ID
                if biometricEnabled {
                    Button(action: unlockWithBiometrics) {
                        VStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.system(size: 36))
                                .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            Text("Use Face ID")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                // Sign out link
                Button(action: {
                    authManager.logout()
                    autoLockManager.onAppLogout()
                }) {
                    Text("Sign out instead")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.6))
                        .underline()
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            if biometricEnabled {
                unlockWithBiometrics()
            }
        }
    }

    private func verifyPassword() {
        guard !passwordInput.isEmpty else { return }
        isVerifying = true
        loginError = nil

        Task {
            let result = await APIService.shared.login(email: savedEmail, password: passwordInput)
            DispatchQueue.main.async {
                isVerifying = false
                switch result {
                case .success(let token):
                    // Odśwież token i odblokuj
                    authManager.currentAPIToken = token
                    KeychainService.save(key: "api_token_\(savedEmail.lowercased())", value: token)
                    autoLockManager.unlock()
                    passwordInput = ""
                    loginError = nil
                case .failure:
                    loginError = "Incorrect password"
                    withAnimation(.default) { shakeAttempts += 1 }
                    passwordInput = ""
                }
            }
        }
    }

    private func unlockWithBiometrics() {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Vault 66") { success, _ in
            DispatchQueue.main.async {
                if success {
                    autoLockManager.unlock()
                } else {
                    // Nie pokazujemy błędu — użytkownik może wpisać hasło
                }
            }
        }
    }
}
