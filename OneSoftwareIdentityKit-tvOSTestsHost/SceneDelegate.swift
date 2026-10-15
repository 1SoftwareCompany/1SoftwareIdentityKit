//
//  SceneDelegate.swift
//  OneSoftwareIdentityKit-tvOSTestsHost
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

        // If the storyboard already created the window,
        // keep the existing configuration.
        if window != nil {
            return
        }

        let window = UIWindow(windowScene: windowScene)

        let storyboard = UIStoryboard(
            name: "Main",
            bundle: nil
        )

        window.rootViewController =
            storyboard.instantiateInitialViewController()
                ?? UIViewController()

        window.makeKeyAndVisible()

        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // No cleanup required for the test host.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // No action required.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // No action required.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // No action required.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // No action required.
    }
}
