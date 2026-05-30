import SwiftUI

// Definicja dostępnych zakładek
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
    
    // Ukrywamy natywny pasek narzędzi, aby użyć naszego customowego
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Główna zawartość przełączana zakładkami
            Group {
                switch selectedTab {
                case .vault:
                    VaultListView()
                case .security:
                    SecuritySettingsView()
                case .sharing:
                    // Placeholder dla ekranu udostępniania
                    PlaceholderView(title: "Sharing Protocol", icon: "person.2.badge.key")
                case .profile:
                    // Placeholder dla profilu
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // --- CUSTOMOWY PASEK DOLNY (TAB BAR) ---
            VStack(spacing: 0) {
                // Linia oddzielająca (subtelna)
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                
                HStack {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20))
                                Text(tab.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(selectedTab == tab ? Color(red: 0.51, green: 0.51, blue: 1) : Color.gray.opacity(0.6))
                            .frame(width: 65, height: 50)
                            // Efekt podświetlenia wybranej zakładki
                            .background(
                                selectedTab == tab ?
                                Color(red: 0.51, green: 0.51, blue: 1).opacity(0.12) :
                                Color.clear
                            )
                            .cornerRadius(12)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 12)
                .background(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.98))
            }
            // Zapewniamy, że pasek nie zasłania zawartości na dole (Safe Area)
            .background(Color(red: 0.07, green: 0.07, blue: 0.08))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// Widok tymczasowy dla brakujących jeszcze ekranów
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
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Module under encryption.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
