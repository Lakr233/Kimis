//
//  UIWindow.swift
//  mTale
//
//  Created by Lakr Aream on 2022/3/31.
//

import UIKit

extension UIWindow {
    static var mainWindow: UIWindow? {
        if let keyWindow = UIApplication
            .shared
            .value(forKey: "keyWindow") as? UIWindow
        {
            return keyWindow
        }
        // if apple remove this shit, we fall back to ugly solution
        let keyWindow = UIApplication
            .shared
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .filter(\.isKeyWindow)
            .first
        return keyWindow
    }

    static var topController: UIViewController? {
        mainWindow?.topController
    }

    var topController: UIViewController? {
        rootViewController?.topMostController
    }
}
