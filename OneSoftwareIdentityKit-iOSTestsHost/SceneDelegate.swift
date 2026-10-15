//
//  SceneDelegate.swift
//  OneSoftwareIdentityKit-iOSTestsHost
//
//  Created by Simeon Yurukov on 15.10.26.
//  Copyright © 2026 Milen Halachev. All rights reserved.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        // Preserve the storyboard's initial view controller.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()

        self.window = window
    }
}
