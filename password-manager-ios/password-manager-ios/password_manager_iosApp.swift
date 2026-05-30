//
//  password_manager_iosApp.swift
//  password-manager-ios
//
//  Created by DevMac on 23/03/2026.
//

import SwiftUI

@main
struct password_manager_iosApp: App {
    @StateObject private var vaultManager = LocalVaultManager()
    @StateObject private var navState = AppNavigationState()
    @StateObject private var authManager = AuthManager()
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("background_timestamp") private var backgroundTimestamp: Double = 0
    @AppStorage("auto_lock_timeout") private var autoLockTimeout: Double = 60
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(vaultManager)
                .environmentObject(authManager)
                .environmentObject(navState)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                // Kiedy aplikacja jest chowana - zapisu jemy czas
                backgroundTimestamp = Date().timeIntervalSince1970
                print("[Auto-Lock] ⏱ Aplikacja w tle. Start odliczania.")
                
            case .active:
                // Kiedy użytkownik wraca - sprawdzamy czas
                if backgroundTimestamp > 0 {
                    let elapsedTime = Date().timeIntervalSince1970 - backgroundTimestamp
                    print("[Auto-Lock] ⏱ Powrót. Minęło: \(Int(elapsedTime)) sekund.")
                    
                    if elapsedTime > autoLockTimeout {
                        print("[Auto-Lock] 🔒 Czas minął! Wylogowuję.")
                        authManager.logout()
                    }
                    
                    backgroundTimestamp = 0 // Reset
                }
                
            default:
                break
            }
        }
    }
}
