import SwiftUI

// Stan aplikacji
enum AppRoute {
    case welcome
    case login
    case register
    case mainTab
}

struct AppRootView: View {
    @State private var currentRoute: AppRoute = .welcome
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()
                
                switch currentRoute {
                case .welcome:
                    WelcomeView(onLogin: { currentRoute = .login },
                                onRegister: { currentRoute = .register })
                case .login:
                    LoginView(onSuccess: { currentRoute = .mainTab },
                              onBack: { currentRoute = .welcome })
                case .register:
                    RegisterView(onSuccess: { currentRoute = .mainTab },
                                 onBack: { currentRoute = .welcome })
                case .mainTab:
                    MainTabView()
                }
            }
        }
    }
}
