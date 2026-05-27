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
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(vaultManager)
                .environmentObject(authManager)
                .environmentObject(navState)
        }
    }
}
