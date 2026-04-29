//
//  password_manager_iosApp.swift
//  password-manager-ios
//
//  Created by DevMac on 23/03/2026.
//

import SwiftUI

@main
struct password_manager_iosApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
