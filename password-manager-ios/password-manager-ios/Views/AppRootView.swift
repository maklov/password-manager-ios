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
    @EnvironmentObject var navState: AppNavigationState // stan globalny
    
    var body: some View {
        NavigationStack{
            Group {
                switch navState.currentRoute { // Zmieniamy tutaj
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
        }
        .preferredColorScheme(.dark)
    }
}
struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNavState = AppNavigationState()
        let previewVaultManager = LocalVaultManager()
        let previewAuthManager = AuthManager()
        
        AppRootView()
            .environmentObject(previewNavState)
            .environmentObject(previewVaultManager)
            .environmentObject(previewAuthManager)
    }
}
