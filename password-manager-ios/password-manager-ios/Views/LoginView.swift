import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    var onSuccess: () -> Void
    var onBack: () -> Void
    
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var rememberEmail: Bool = true
    @AppStorage("biometric_unlock_enabled") private var biometricUnlockEnabled: Bool = false
    @AppStorage("last_logged_email") private var savedEmail: String = ""
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Vault 66")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    // Pusty element dla balansu HStack
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Nagłówek (Ikona + Tekst)
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))
                                        .font(.system(size: 30))
                                )
                            
                            VStack(spacing: 8) {
                                Text("Vault 66")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("Welcome back")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Formularz
                        VStack(spacing: 20) {
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EMAIL ADDRESS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    TextField("name@domain.com", text: $emailInput)
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .cornerRadius(12)
                            }
                            
                            // Hasło
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ACCOUNT PASSWORD")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    SecureField("••••••••", text: $passwordInput)
                                        .foregroundColor(.white)
                                    Image(systemName: "eye.slash.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .cornerRadius(12)
                            }
                            
                            // Opcje
                            HStack {
                                Toggle(isOn: $rememberEmail) {
                                    Text("Remember my email")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.51, green: 0.51, blue: 1)))
                                
                                Spacer()
                                
                                Button("Forgot password?") {
                                    // Akcja resetu
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Główny przycisk logowania
                        Button(action: {
                            authManager.loginWith(masterPassword: passwordInput, email: emailInput)
                        }) { // Tymczasowo od razu przenosi do aplikacji
                            HStack {
                                Text("Sign In")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.51, green: 0.51, blue: 1))
                            .cornerRadius(12)
                            .shadow(color: Color(red: 0.51, green: 0.51, blue: 1).opacity(0.3), radius: 15, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                            if isAuthenticated {
                                onSuccess() // To przekaże sygnał do AppRootView, żeby zmienić ekran na .mainTab!
                            }
                        }
                        
                        if biometricUnlockEnabled {
                            Button(action: {
                                authManager.loginWithFaceID()
                            }) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                            }
                        } else {
                            // Jeśli biometria jest wyłączona, wyświetlamy informację, że trzeba użyć hasła
                            Text("Biometrics disabled in settings")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 8) {
                            Circle().fill(Color.purple).frame(width: 6, height: 6)
                            Text("ENCRYPTED VIA AES-GCM")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.top, 30)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Jeśli system ma w pamięci jakiegoś maila, od razu wpisz go w pole!
            if !savedEmail.isEmpty {
                emailInput = savedEmail
            }
            
            // Jeśli Face ID jest włączone i mamy maila, automatycznie uruchom skaner
            if biometricUnlockEnabled && !savedEmail.isEmpty {
                authManager.loginWithFaceID()
            }
        }
    }
}
