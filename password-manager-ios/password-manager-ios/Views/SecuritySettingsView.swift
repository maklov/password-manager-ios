import SwiftUI

struct SecuritySettingsView: View {
    @EnvironmentObject var navState: AppNavigationState
    @State private var biometricUnlock = true
    @State private var selfDestruct = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Encryption\nThresholds")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Define the perimeter of your digital sanctuary with high-fidelity biometric and structural protocols.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                // Karta Statusu
                VStack(alignment: .leading, spacing: 16) {
                    Text("SANCTUARY STATUS")
                        .font(.system(size: 10, weight: .bold))
                    Text("Maximum Level")
                        .font(.system(size: 24, weight: .bold))
                    ProgressView(value: 0.94)
                        .tint(Color.purple)
                    HStack {
                        Text("94% Secure")
                        Spacer()
                        Text("Last Audit: 2m ago")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                
                // Togle i linki
                VStack(spacing: 1) {
                    SecurityToggle(title: "Biometric Unlock", subtitle: "FaceID / TouchID Protocol", isOn: $biometricUnlock, icon: "faceid")
                    SecurityRow(title: "Auto-lock Timeout", subtitle: "Immediately", icon: "timer")
                    SecurityToggle(title: "Self-Destruct", subtitle: "Erase data after 10 failures", isOn: $selfDestruct, icon: "exclamationmark.triangle", color: .red)
                }
                .background(Color.white.opacity(0.03))
                .cornerRadius(20)
            }
            .padding(24)
            Button(action: {
                    // TUTAJ W PRZYSZŁOŚCI: authManager.clearMasterKey() - ZABIJEMY KLUCZ W RAM
                    navState.currentRoute = .welcome // Powrót na ekran główny!
                }) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Lock Vault & Disconnect")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(16)
                }
                .padding(.top, 20)
                .padding(.bottom, 100) // Żeby nie wchodziło pod TabBar
            }
            .padding(24)
        }
        }


// Pomocnicze komponenty do wierszy
struct SecurityToggle: View {
    let title: String; let subtitle: String; @Binding var isOn: Bool; let icon: String; var color: Color = .blue
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(color)
        }
        .padding()
    }
}

struct SecurityRow: View {
    let title: String; let subtitle: String; let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }
        .padding()
    }
}
