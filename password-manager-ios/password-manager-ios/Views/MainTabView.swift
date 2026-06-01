import SwiftUI

enum Tab: String, CaseIterable {
    case vault = "VAULT"
    case security = "SECURITY"
    case sharing = "SHARING"
    case profile = "PROFILE"

    var icon: String {
        switch self {
        case .vault: return "lock.fill"
        case .security: return "shield.fill"
        case .sharing: return "person.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .vault
    @EnvironmentObject var autoLockManager: AutoLockManager
    @EnvironmentObject var vaultManager: LocalVaultManager

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .vault:
                    VaultListView()
                case .security:
                    SecuritySettingsView()
                        .environmentObject(vaultManager)
                case .sharing:
                    PlaceholderView(title: "Sharing Protocol", icon: "person.2.badge.key")
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)

                HStack {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) { selectedTab = tab }
                            autoLockManager.registerActivity()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: tab.icon).font(.system(size: 20))
                                Text(tab.rawValue).font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(selectedTab == tab ? Color(red: 0.51, green: 0.51, blue: 1) : Color.gray.opacity(0.6))
                            .frame(width: 65, height: 50)
                            .background(
                                selectedTab == tab ?
                                Color(red: 0.51, green: 0.51, blue: 1).opacity(0.12) : Color.clear
                            )
                            .cornerRadius(12)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 12)
                .background(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.98))
            }
            .background(Color(red: 0.07, green: 0.07, blue: 0.08))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Rejestruj aktywność przez timer — sprawdza czy użytkownik coś robi co 5s
        // zamiast przechwytywać gesty
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            autoLockManager.registerActivity()
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 1).opacity(0.5))
                Text(title).font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Module under encryption.").font(.caption).foregroundColor(.gray)
            }
        }
    }
}
