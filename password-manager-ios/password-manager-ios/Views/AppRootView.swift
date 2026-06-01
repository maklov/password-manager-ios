import SwiftUI

class AppNavigationState: ObservableObject {
    @Published var currentRoute: AppRoute = .welcome
}

enum AppRoute {
    case welcome
    case login
    case register
    case mainTab
}

struct AppRootView: View {
    @EnvironmentObject var navState: AppNavigationState
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var autoLockManager: AutoLockManager

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Routing bez NavigationStack — każdy widok ma własny jeśli potrzebuje
            Group {
                switch navState.currentRoute {
                case .welcome:
                    WelcomeView(
                        onLogin: { navState.currentRoute = .login },
                        onRegister: { navState.currentRoute = .register }
                    )
                case .login:
                    LoginView(
                        onSuccess: { navState.currentRoute = .mainTab },
                        onBack: { navState.currentRoute = .welcome }
                    )
                case .register:
                    RegisterView(
                        onSuccess: { navState.currentRoute = .mainTab },
                        onBack: { navState.currentRoute = .welcome }
                    )
                case .mainTab:
                    MainTabView()
                }
            }
            .animation(.easeInOut, value: navState.currentRoute)

            // Ekran blokady — overlay na całej aplikacji
            if autoLockManager.isLocked && navState.currentRoute == .mainTab {
                LockScreenView()
                    .environmentObject(authManager)
                    .environmentObject(autoLockManager)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: autoLockManager.isLocked)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                autoLockManager.onAppBackground()
            case .active:
                autoLockManager.onAppForeground()
            default:
                break
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuth in
            if isAuth { autoLockManager.onAppAuthenticated() }
            else { autoLockManager.onAppLogout() }
        }
        .onChange(of: navState.currentRoute) { route in
            if route != .mainTab { autoLockManager.onAppLogout() }
        }
    }
}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
            .environmentObject(AppNavigationState())
            .environmentObject(LocalVaultManager())
            .environmentObject(AuthManager())
            .environmentObject(AutoLockManager())
    }
}
