import SwiftUI

enum LoginFocusField: Hashable {
    case email, password
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    var onSuccess: () -> Void
    var onBack: () -> Void

    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var rememberEmail: Bool = true
    @State private var showSessionExpiredBanner = false


    @AppStorage("biometric_unlock_enabled") private var biometricUnlockEnabled: Bool = false
    @AppStorage("last_logged_email") private var savedEmail: String = ""

    @FocusState private var focusedField: LoginFocusField?

    @State private var touchedEmail = false
    @State private var touchedPassword = false
    @State private var loginFailed = false
    @State private var shakeAttempts: CGFloat = 0

    // MARK: - Validation
    private var emailError: String? {
        guard touchedEmail, !emailInput.isEmpty else { return nil }
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        let valid = emailInput.range(of: regex, options: .regularExpression) != nil
        return valid ? nil : "Invalid email format"
    }

    private var passwordError: String? {
        guard touchedPassword, !passwordInput.isEmpty else { return nil }
        if loginFailed { return "Incorrect email or password" }
        return nil
    }

    private var canSubmit: Bool {
        !emailInput.isEmpty && !passwordInput.isEmpty && emailError == nil
    }

    // MARK: - Actions
    private func handleLogin() {
        touchedEmail = true
        touchedPassword = true
        authManager.loginError = nil  // ← DODAJ

        guard canSubmit else {
            withAnimation(.default) { shakeAttempts += 1 }
            return
        }

        authManager.loginWith(masterPassword: passwordInput, email: emailInput)
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 24) {
                // Nav
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Vault 66").font(.headline).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {

                        // Header
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
                        if showSessionExpiredBanner {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .foregroundColor(.orange)
                                Text("Your session expired. Please log in again.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Form
                        VStack(spacing: 20) {
                            ValidatedField(
                                title: "EMAIL ADDRESS",
                                placeholder: "name@domain.com",
                                text: $emailInput,
                                error: emailError,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                submitLabel: .next,
                                onSubmit: { focusedField = .password },
                                onEditingChanged: {
                                    touchedEmail = true
                                    loginFailed = false
                                }
                            )
                            .focused($focusedField, equals: .email)

                            ValidatedField(
                                title: "ACCOUNT PASSWORD",
                                placeholder: "••••••••",
                                text: $passwordInput,
                                error: authManager.loginError ?? passwordError,  // ← błąd z API ma priorytet
                                isSecure: true,
                                submitLabel: .done,
                                onSubmit: { handleLogin() },
                                onEditingChanged: {
                                    touchedPassword = true
                                    authManager.loginError = nil  // ← czyść błąd przy pisaniu
                                }
                            )
                            .focused($focusedField, equals: .password)

                            HStack {
                                Toggle(isOn: $rememberEmail) {
                                    Text("Remember my email")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.51, green: 0.51, blue: 1)))

                                Spacer()

                                Button("Forgot password?") {}
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))
                            }
                        }
                        .padding(.horizontal, 24)

                        // Sign in button
                        Button(action: handleLogin) {
                            HStack {
                                Text("Sign In")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(canSubmit ? Color(red: 0.08, green: 0.08, blue: 0.4) : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSubmit ? Color(red: 0.51, green: 0.51, blue: 1) : Color(red: 0.16, green: 0.16, blue: 0.17))
                            .cornerRadius(12)
                            .shadow(
                                color: canSubmit ? Color(red: 0.51, green: 0.51, blue: 1).opacity(0.3) : .clear,
                                radius: 15, y: 5
                            )
                            .animation(.easeInOut(duration: 0.2), value: canSubmit)
                        }
                        .modifier(ShakeEffect(animatableData: shakeAttempts))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .onChange(of: authManager.loginError) { error in
                            if error != nil {
                                withAnimation(.default) { shakeAttempts += 1 }
                            }
                        }
                        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                            if isAuthenticated {
                                onSuccess()
                            }
                        }

                        // Biometric
                        if biometricUnlockEnabled {
                            Button(action: { authManager.loginWithFaceID() }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1))
                                    Text("Use Face ID")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
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
            if authManager.sessionExpired {
                    showSessionExpiredBanner = true
                    authManager.sessionExpired = false
            }
            if !savedEmail.isEmpty {
                emailInput = savedEmail
                focusedField = .password
            } else {
                focusedField = .email
            }
            if biometricUnlockEnabled && !savedEmail.isEmpty {
                authManager.loginWithFaceID()
            }
        }
        .onChange(of: authManager.sessionExpired) { expired in
            if expired {
                showSessionExpiredBanner = true
                authManager.sessionExpired = false
            }
        }
    }
}
