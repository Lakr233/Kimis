//
//  AppDelegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/14.
//

import AVKit
import BackgroundTasks
import IQKeyboardManagerSwift
import SPIndicator
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UINavigationBar.appearance().tintColor = .accent
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(PostEditorController.self)
        prepareAppTasks()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { result, error in
            print("[*] request notification permission result \(result) \(error?.localizedDescription ?? "nil")")
        }
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("[*] \(application) \(#function)")
        // clean up
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(.banner)
    }
}

extension AppDelegate {
    func prepareAppTasks() {
        prepareAppTaskForNotifications()
    }

    private func prepareAppTaskForNotifications() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppTask.fetchNotifications.rawValue,
            using: AppTask.queue
        ) { task in
            AppTask.scheduleFetchNotifications()
            AppTask.handleFetchNotifications(task: task as! BGAppRefreshTask)
        }
        AppTask.scheduleFetchNotifications()
    }
}
