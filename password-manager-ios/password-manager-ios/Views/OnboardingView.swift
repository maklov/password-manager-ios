import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var understood1 = false
    @State private var understood2 = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(currentPage == index
                                ? Color(red: 0.51, green: 0.51, blue: 1)
                                : Color.white.opacity(0.15))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3(understood1: $understood1, understood2: $understood2).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                VStack(spacing: 12) {
                    Button(action: handleNext) {
                        HStack {
                            Text(currentPage < 2 ? "Continue" : "I understand — Get Started")
                                .font(.system(size: 16, weight: .bold))
                            if currentPage < 2 {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(canProceed ? Color(red: 0.08, green: 0.08, blue: 0.4) : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canProceed
                            ? Color(red: 0.51, green: 0.51, blue: 1)
                            : Color(red: 0.16, green: 0.16, blue: 0.17))
                        .cornerRadius(14)
                        .animation(.easeInOut(duration: 0.2), value: canProceed)
                    }
                    .disabled(!canProceed)

                    if currentPage < 2 {
                        Button(action: { currentPage = 2 }) {
                            Text("Skip intro")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private var canProceed: Bool {
        if currentPage == 2 { return understood1 && understood2 }
        return true
    }

    private func handleNext() {
        if currentPage < 2 {
            withAnimation { currentPage += 1 }
        } else {
            UserDefaults.standard.set(true, forKey: "onboarding_completed")
            onComplete()
        }
    }
}

// MARK: - Page 1
struct OnboardingPage1: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.08))
                        .frame(width: 160, height: 160).blur(radius: 20)
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color(red: 0.51, green: 0.51, blue: 1).opacity(0.2), radius: 20)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(LinearGradient(
                                colors: [Color(red: 0.76, green: 0.76, blue: 1), Color(red: 0.51, green: 0.51, blue: 1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    Text("Welcome to Vault 66")
                        .font(.system(size: 30, weight: .heavy)).foregroundColor(.white).multilineTextAlignment(.center)
                    Text("Your personal zero-knowledge password manager")
                        .font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    FeatureCard(icon: "brain.head.profile", color: Color(red: 0.51, green: 0.51, blue: 1),
                        title: "Zero-Knowledge",
                        description: "Your passwords are encrypted on your device before leaving it. Even we cannot read them.")
                    FeatureCard(icon: "key.fill", color: .green,
                        title: "Your password = Your key",
                        description: "Your master password is the only key to your vault. It never leaves your device — not even to our servers.")
                    FeatureCard(icon: "icloud.fill", color: .blue,
                        title: "Encrypted sync",
                        description: "Passwords sync across devices in encrypted form. The server stores only ciphertext — never plaintext.")
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 28).padding(.bottom, 24)
        }
    }
}

// MARK: - Page 2
struct OnboardingPage2: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.08)).frame(width: 160, height: 160).blur(radius: 20)
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.14)).frame(width: 100, height: 100)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44)).foregroundColor(.orange)
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    Text("What if you forget\nyour password?")
                        .font(.system(size: 28, weight: .heavy)).foregroundColor(.white).multilineTextAlignment(.center)
                    Text("This is the most important thing to understand before creating your vault.")
                        .font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ConsequenceRow(icon: "xmark.circle.fill", color: .red,
                        title: "No password reset option",
                        description: "Because of zero-knowledge encryption, there is no \"forgot password\" feature. Your master password is mathematically linked to your encryption key — without it, your data cannot be decrypted by anyone, including us.")
                    Divider().background(Color.white.opacity(0.08))
                    ConsequenceRow(icon: "xmark.circle.fill", color: .red,
                        title: "No recovery backdoor",
                        description: "There is no emergency code, no recovery email, no support ticket that can restore your vault. This is a deliberate security decision — a backdoor for you is a backdoor for attackers.")
                    Divider().background(Color.white.opacity(0.08))
                    ConsequenceRow(icon: "trash.fill", color: .red,
                        title: "Lost password = Lost data",
                        description: "If you forget your master password, the only option is to delete your account and start over. All stored passwords will be permanently lost.")
                }
                .padding(20)
                .background(Color.red.opacity(0.06))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 28).padding(.bottom, 24)
        }
    }
}

// MARK: - Page 3
struct OnboardingPage3: View {
    @Binding var understood1: Bool
    @Binding var understood2: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ZStack {
                    Circle().fill(Color.green.opacity(0.08)).frame(width: 160, height: 160).blur(radius: 20)
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.14)).frame(width: 100, height: 100)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 44)).foregroundColor(.green)
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    Text("How to protect\nyour access")
                        .font(.system(size: 28, weight: .heavy)).foregroundColor(.white).multilineTextAlignment(.center)
                    Text("Follow these recommendations to never lose access to your vault.")
                        .font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    TipCard(icon: "pencil.and.paper", color: .green,
                        title: "Write it down physically",
                        description: "Write your master password on paper and store it in a safe or lockbox. Never store it digitally in plaintext.")
                    TipCard(icon: "person.2.fill", color: .blue,
                        title: "Tell a trusted person",
                        description: "Consider sharing it with a trusted family member or keeping a sealed envelope in a secure location.")
                    TipCard(icon: "textformat.abc", color: Color(red: 0.51, green: 0.51, blue: 1),
                        title: "Use a memorable passphrase",
                        description: "Choose 4 unrelated words: apple-tower-river-cloud. Long passphrases are both secure and memorable.")

                    // Backup card — nowy
                    TipCard(icon: "externaldrive.fill", color: .orange,
                        title: "Export encrypted backup",
                        description: "Use the Backup tab to export your vault as an encrypted .vault66 file. Store it on a USB drive or cloud. You'll need a separate export password to open it.")

                    TipCard(icon: "exclamationmark.triangle", color: .red,
                        title: "Never store it in this app",
                        description: "Do not store your master password as a vault entry — if you lose access, you lose the key to unlock it.")
                }
                .padding(.horizontal, 4)

                // Confirmations
                VStack(spacing: 12) {
                    Text("BEFORE YOU CONTINUE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ConfirmationRow(isChecked: $understood1,
                        text: "I understand that if I forget my master password, my data cannot be recovered by anyone.")
                    ConfirmationRow(isChecked: $understood2,
                        text: "I have a plan for safely storing my master password and will use encrypted backups.")
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 28).padding(.bottom, 24)
        }
    }
}

// MARK: - Subcomponents
struct FeatureCard: View {
    let icon: String; let color: Color; let title: String; let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(description).font(.system(size: 13)).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .cornerRadius(12)
    }
}

struct TipCard: View {
    let icon: String; let color: Color; let title: String; let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(description).font(.system(size: 13)).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .cornerRadius(12)
    }
}

struct ConsequenceRow: View {
    let icon: String; let color: Color; let title: String; let description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            }
            Text(description).font(.system(size: 14))
                .foregroundColor(Color(red: 0.76, green: 0.78, blue: 0.84))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ConfirmationRow: View {
    @Binding var isChecked: Bool
    let text: String
    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { isChecked.toggle() } }) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isChecked ? Color(red: 0.51, green: 0.51, blue: 1) : Color.white.opacity(0.08))
                        .frame(width: 24, height: 24)
                    if isChecked {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.2), value: isChecked)
                Text(text).font(.system(size: 13))
                    .foregroundColor(isChecked ? .white : .gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: isChecked)
                Spacer(minLength: 0)
            }
        }
    }
}
