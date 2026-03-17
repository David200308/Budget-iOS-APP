//
//  SceneDelegate.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2026 David Jiang. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 16.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // One-time migration: copies legacy GRDB SQLite data into Core Data
        MigrationService.migrateIfNeeded(into: PersistenceController.shared.context)

        let stateController = StateController()
        let rootView = BudgetView()
            .environmentObject(stateController)
            .environmentObject(SettingsManager.shared)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()
    }
}
