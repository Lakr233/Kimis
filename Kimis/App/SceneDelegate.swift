//
//  SceneDelegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/14.
//

import AVFoundation
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        #if targetEnvironment(macCatalyst)
            if let titlebar = windowScene.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }
        #endif
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 500, height: 500)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootController()
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_: UIScene) {
        do {
            _ = try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: .mixWithOthers,
            )
        } catch {
            print(error.localizedDescription)
        }
    }
}
