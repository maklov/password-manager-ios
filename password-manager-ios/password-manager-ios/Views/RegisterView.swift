import SwiftUI

struct RegisterView: View {
    var onSuccess: () -> Void
    var onBack: () -> Void
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var masterPassword: String = ""
    @State private var confirmPassword: String = ""
    
    // Prosta logika siły hasła (do rozbudowy)
    private var passwordStrength: Double {
        let length = Double(masterPassword.count)
        return min(length / 12.0, 1.0) // Pełny pasek przy 12 znakach
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Pasek nawigacji
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Vault Sentinel")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Nagłówek
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
                        
                        // Pola
                        VStack(spacing: 20) {
                            RegisterField(title: "FULL NAME", placeholder: "Julian Thorne", text: $fullName)
                            RegisterField(title: "EMAIL ADDRESS", placeholder: "julian@sentinel.com", text: $email)
                            
                            // Master Password z siłą hasła
                            VStack(alignment: .leading, spacing: 8) {
                                Text("MASTER PASSWORD")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                HStack {
                                    SecureField("••••••••••••", text: $masterPassword)
                                        .foregroundColor(.white)
                                    Image(systemName: "eye.slash.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.17))
                                .cornerRadius(12)
                                
                                // Wskaźnik siły
                                HStack {
                                    Text("Strength: \(passwordStrength > 0.7 ? "Robust" : "Weak")")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(passwordStrength * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 4)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .frame(width: geometry.size.width, height: 4)
                                            .foregroundColor(Color.white.opacity(0.1))
                                        Capsule()
                                            .frame(width: geometry.size.width * CGFloat(passwordStrength), height: 4)
                                            .foregroundColor(passwordStrength > 0.7 ? Color(red: 0.51, green: 0.51, blue: 1) : Color.red)
                                    }
                                }
                                .frame(height: 4)
                            }
                            
                            RegisterField(title: "CONFIRM PASSWORD", placeholder: "••••••••••••", text: $confirmPassword, isSecure: true)
                        }
                        
                        // Przycisk Rejestracji
                        Button(action: onSuccess) {
                            HStack {
                                Text("Create Account")
                                Image(systemName: "waveform.path") // Zbliżone do ikony ze Stitcha
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.51, green: 0.51, blue: 1))
                            .cornerRadius(12)
                        }
                        .padding(.top, 16)
                        
                        // Log in link
                        HStack {
                            Spacer()
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            Button(action: {
                                // Zmieniamy stan na logowanie (w AppRootView)
                                // Tutaj wywołujemy onBack dla uproszczenia (powrót do Welcome),
                                // ale w przyszłości można dodać onSwitchToLogin
                                onBack()
                            }) {
                                Text("Log in")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
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
    }
}

// Pomocniczy komponent pola dla powtarzalności
struct RegisterField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.17))
            .cornerRadius(12)
        }
    }
}
