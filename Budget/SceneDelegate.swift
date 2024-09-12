//
//  SceneDelegate.swift
//  Budget
//
//  Created by David Jiang.
//  Copyright © 2023 David Jiang. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 16.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }
		let window = UIWindow(windowScene: windowScene)
		let rootView = BudgetView()
			.environmentObject(StateController())
		window.rootViewController = UIHostingController(rootView: rootView)
		self.window = window
		window.makeKeyAndVisible()
	}
}
