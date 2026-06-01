import SwiftUI

enum RegisterFocusField: Hashable {
    case fullName, email, masterPassword, confirmPassword
}

// MARK: - Validation Helpers
private func isValidEmail(_ email: String) -> Bool {
    let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
    return email.range(of: regex, options: .regularExpression) != nil
}

private func isValidFullName(_ name: String) -> Bool {
    let parts = name.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").filter { !$0.isEmpty }
    return parts.count >= 2
}

private func isValidMasterPassword(_ password: String) -> Bool {
    let wordPattern = #"^[^\-]+-[^\-]+-[^\-]+-[^\-]+$"#
    let hasWords = password.range(of: wordPattern, options: .regularExpression) != nil
    return hasWords || password.count >= 12
}

// MARK: - Shake Modifier
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - RegisterView
struct RegisterView: View {
    var onSuccess: () -> Void
    var onBack: () -> Void

    @EnvironmentObject var authManager: AuthManager

    @State private var fullNameInput: String = ""
    @State private var emailInput: String = ""
    @State private var masterPasswordInput: String = ""
    @State private var confirmPasswordInput: String = ""

    @FocusState private var focusedField: RegisterFocusField?

    @State private var touchedName = false
    @State private var touchedEmail = false
    @State private var touchedPassword = false
    @State private var touchedConfirm = false

    @State private var isCheckingEmail = false
    @State private var emailExistsError = false

    @State private var shakeAttempts: CGFloat = 0
    @State private var showExitConfirm = false

    // MARK: - Validation
    private var nameError: String? {
        guard touchedName, !fullNameInput.isEmpty else { return nil }
        return isValidFullName(fullNameInput) ? nil : "Enter first and last name"
    }

    private var emailError: String? {
        guard touchedEmail, !emailInput.isEmpty else { return nil }
        if !isValidEmail(emailInput) { return "Invalid email format" }
        if emailExistsError { return "Account with this email already exists" }
        return nil
    }

    private var passwordError: String? {
        guard touchedPassword, !masterPasswordInput.isEmpty else { return nil }
        return isValidMasterPassword(masterPasswordInput) ? nil : "Min. 12 characters or 4 words separated by hyphens"
    }

    private var confirmError: String? {
        guard touchedConfirm, !confirmPasswordInput.isEmpty else { return nil }
        return confirmPasswordInput == masterPasswordInput ? nil : "Passwords do not match"
    }

    private var isFormDirty: Bool {
        !fullNameInput.isEmpty || !emailInput.isEmpty || !masterPasswordInput.isEmpty || !confirmPasswordInput.isEmpty
    }

    private var canSubmit: Bool {
        isValidFullName(fullNameInput) &&
        isValidEmail(emailInput) &&
        isValidMasterPassword(masterPasswordInput) &&
        confirmPasswordInput == masterPasswordInput &&
        !emailExistsError
    }

    private var passwordStrength: Double {
        min(Double(masterPasswordInput.count) / 12.0, 1.0)
    }

    // MARK: - Actions
    private func handleCreateAccount() {
        touchedName = true
        touchedEmail = true
        touchedPassword = true
        touchedConfirm = true

        guard canSubmit else {
            withAnimation(.default) { shakeAttempts += 1 }
            return
        }

        Task {
            let result = await APIService.shared.register(email: emailInput, password: masterPasswordInput)
            DispatchQueue.main.async {
                switch result {
                case .success:
                    UserDefaults.standard.set(emailInput, forKey: "last_logged_email")
                    let components = fullNameInput
                        .trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: " ")
                        .filter { !$0.isEmpty }
                    UserDefaults.standard.set(components.first ?? "", forKey: "profile_first_name")
                    UserDefaults.standard.set(components.dropFirst().joined(separator: " "), forKey: "profile_last_name")
                    authManager.loginWith(masterPassword: masterPasswordInput, email: emailInput)
                case .failure(let error):
                    print("❌ BŁĄD REJESTRACJI: \(error)")
                    withAnimation(.default) { shakeAttempts += 1 }
                }
            }
        }
    }

    private func checkEmailExists() async {
        guard isValidEmail(emailInput) else { return }
        isCheckingEmail = true
        let host = Bundle.main.object(forInfoDictionaryKey: "ApiHostUrl") as? String ?? ""
        let encoded = emailInput.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "http://\(host)/api/\(encoded)/salt"
        if let url = URL(string: urlString),
           let (_, response) = try? await URLSession.shared.data(from: url),
           let http = response as? HTTPURLResponse {
            DispatchQueue.main.async {
                emailExistsError = (http.statusCode == 200)
                isCheckingEmail = false
            }
        } else {
            DispatchQueue.main.async { isCheckingEmail = false }
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button(action: {
                        if isFormDirty { showExitConfirm = true } else { onBack() }
                    }) {
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
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.76, green: 0.76, blue: 1))
                                .frame(width: 48, height: 48)
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .cornerRadius(12)

                            Text("Create your\nsanctuary")
                                .font(.system(size: 40, weight: .heavy))
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Text("Enter your details to establish your encrypted digital perimeter.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))
                        }
                        .padding(.top, 16)

                        VStack(spacing: 20) {

                            // Full Name
                            ValidatedField(
                                title: "FULL NAME",
                                placeholder: "Julian Thorne",
                                text: $fullNameInput,
                                error: nameError,
                                keyboardType: .default,
                                autocapitalization: .words,
                                submitLabel: .next,
                                onSubmit: { focusedField = .email },
                                onEditingChanged: { touchedName = true }
                            )
                            .focused($focusedField, equals: .fullName)

                            // Email
                            ValidatedField(
                                title: "EMAIL ADDRESS",
                                placeholder: "julian@sentinel.com",
                                text: $emailInput,
                                error: emailError,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                submitLabel: .next,
                                trailingView: isCheckingEmail ? AnyView(
                                    ProgressView().scaleEffect(0.7).tint(.gray)
                                ) : nil,
                                onSubmit: { focusedField = .masterPassword },
                                onEditingChanged: {
                                    touchedEmail = true
                                    emailExistsError = false
                                }
                            )
                            .focused($focusedField, equals: .email)
                            .onChange(of: focusedField) { field in
                                if field != .email && touchedEmail {
                                    Task { await checkEmailExists() }
                                }
                            }

                            // Master Password
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("MASTER PASSWORD")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(masterPasswordInput.count)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(masterPasswordInput.count >= 12 ? Color(red: 0.51, green: 0.51, blue: 1) : .gray)
                                        .animation(.easeInOut, value: masterPasswordInput.count)
                                }

                                SecureField("••••••••••••", text: $masterPasswordInput)
                                    .foregroundColor(.white)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .confirmPassword }
                                    .focused($focusedField, equals: .masterPassword)
                                    .onChange(of: masterPasswordInput) { _ in touchedPassword = true }
                                    .padding()
                                    .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12).stroke(
                                            passwordError != nil ? Color.red.opacity(0.6) :
                                            (touchedPassword && isValidMasterPassword(masterPasswordInput) ? Color(red: 0.51, green: 0.51, blue: 1).opacity(0.5) : Color.clear),
                                            lineWidth: 1
                                        )
                                    )

                                HStack {
                                    Text("Strength: \(passwordStrength > 0.7 ? "Robust" : passwordStrength > 0.4 ? "Fair" : "Weak")")
                                        .font(.caption)
                                        .foregroundColor(passwordStrength > 0.7 ? Color(red: 0.51, green: 0.51, blue: 1) : passwordStrength > 0.4 ? .orange : .red)
                                    Spacer()
                                    Text("\(Int(passwordStrength * 100))%")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                .padding(.top, 2)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .frame(width: geometry.size.width, height: 4)
                                            .foregroundColor(Color.white.opacity(0.1))
                                        Capsule()
                                            .frame(width: geometry.size.width * CGFloat(passwordStrength), height: 4)
                                            .foregroundColor(
                                                passwordStrength > 0.7 ? Color(red: 0.51, green: 0.51, blue: 1) :
                                                passwordStrength > 0.4 ? .orange : .red
                                            )
                                            .animation(.easeInOut, value: passwordStrength)
                                    }
                                }
                                .frame(height: 4)

                                if touchedPassword && passwordError != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill").font(.system(size: 11))
                                        Text(passwordError!).font(.system(size: 11))
                                    }
                                    .foregroundColor(.red)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                } else if !masterPasswordInput.isEmpty && passwordError == nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle").font(.system(size: 11))
                                        Text("Tip: use 4 words separated by hyphens, e.g. apple-sky-river-tower")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(.gray)
                                    .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: passwordError)

                            // Confirm Password
                            ValidatedField(
                                title: "CONFIRM PASSWORD",
                                placeholder: "••••••••••••",
                                text: $confirmPasswordInput,
                                error: confirmError,
                                isSecure: true,
                                submitLabel: .done,
                                onSubmit: { handleCreateAccount() },
                                onEditingChanged: { touchedConfirm = true }
                            )
                            .focused($focusedField, equals: .confirmPassword)
                        }

                        // Submit
                        Button(action: handleCreateAccount) {
                            HStack {
                                Text("Create Account")
                                Image(systemName: "waveform.path")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(canSubmit ? Color(red: 0.08, green: 0.08, blue: 0.4) : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSubmit ? Color(red: 0.51, green: 0.51, blue: 1) : Color(red: 0.16, green: 0.16, blue: 0.17))
                            .cornerRadius(12)
                            .animation(.easeInOut(duration: 0.2), value: canSubmit)
                        }
                        .modifier(ShakeEffect(animatableData: shakeAttempts))
                        .padding(.top, 16)

                        HStack {
                            Spacer()
                            Text("Already have an account?").foregroundColor(.gray).font(.system(size: 14))
                            Button(action: {
                                if isFormDirty { showExitConfirm = true } else { onBack() }
                            }) {
                                Text("Log in").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear { focusedField = .fullName }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated { onSuccess() }
        }
        .confirmationDialog("Discard changes?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { onBack() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("You have unsaved data. Going back will discard it.")
        }
    }
}

// MARK: - ValidatedField (shared component)
struct ValidatedField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var error: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .next
    var trailingView: AnyView? = nil
    var onSubmit: () -> Void = {}
    var onEditingChanged: () -> Void = {}

    @State private var isPasswordVisible: Bool = false

    private var borderColor: Color {
        if error != nil { return .red.opacity(0.6) }
        if !text.isEmpty { return Color(red: 0.51, green: 0.51, blue: 1).opacity(0.5) }
        return Color.clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)

            HStack {
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(placeholder, text: $text)
                            .submitLabel(submitLabel)
                            .onSubmit(onSubmit)
                            .onChange(of: text) { _ in onEditingChanged() }
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled()
                            .submitLabel(submitLabel)
                            .onSubmit(onSubmit)
                            .onChange(of: text) { _ in onEditingChanged() }
                    }
                }
                .foregroundColor(.white)

                if let trailing = trailingView { trailing }

                if isSecure {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
            .animation(.easeInOut(duration: 0.15), value: error != nil)

            if let errorMsg = error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 11))
                    Text(errorMsg).font(.system(size: 11))
                }
                .foregroundColor(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: error != nil)
    }
}
