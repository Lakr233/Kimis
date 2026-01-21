//
//  Utils.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/4/29.
//

import SPIndicator
import UIKit

private func SPIndicatorPresent(
    title: String,
    preset: SPIndicatorIconPreset,
    haptic: SPIndicatorHaptic,
    from presentSide: SPIndicatorPresentSide = .top,
    completion: (() -> Void)? = nil,
) {
    let alertView = SPIndicatorView(title: title, message: nil, preset: preset)
    alertView.presentSide = presentSide
    alertView.iconView?.tintColor = .accent
    alertView.present(haptic: haptic, completion: completion)
}

func presentMessage(_ message: String) {
    withMainActor {
        SPIndicatorPresent(
            title: message.trimmingCharacters(in: .whitespacesAndNewlines),
            preset: .done,
            haptic: .success,
            from: .top,
            completion: nil,
        )
    }
}

private let kTrimmingTailDots = ["。", "."]

func presentError(_ error: String) {
    var error = error
    for dot in kTrimmingTailDots {
        while error.hasSuffix(dot) {
            error.removeLast()
        }
    }
    error = error
        .components(separatedBy: " ")
        .enumerated()
        .map { idx, val -> String in
            if idx == 0 {
                return val.localizedCapitalized
            } else {
                return val
            }
        }
        .joined(separator: " ")
    withMainActor {
        SPIndicatorPresent(
            title: error,
            preset: .error,
            haptic: .error,
            from: .top,
            completion: nil,
        )
    }
}

func presentError(_ error: Error) {
    presentError(error.localizedDescription)
}

func presentConfirmation(message: String, onConfim: (() -> Void)? = nil, onCancel: (() -> Void)? = nil, refView: UIView? = nil) {
    let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "YES", style: .destructive, handler: { _ in onConfim?() }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in onCancel?() }))
    let controller = (refView?.window ?? UIWindow.mainWindow)?.topController
    controller?.present(alert, animated: true)
}

func withMainActor(delay: Double = 0, _ calling: @escaping () -> Void) {
    guard Thread.isMainThread, delay <= 0 else {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: calling)
        return
    }
    calling()
}

func withUIKitAnimation(duration: Double = 0.5, _ calling: @escaping () -> Void, completion: (() -> Void)? = nil) {
    guard Thread.isMainThread else {
        DispatchQueue.main.async {
            withUIKitAnimation(calling, completion: completion)
        }
        return
    }
    UIView.animate(
        withDuration: duration,
        delay: 0,
        usingSpringWithDamping: 1,
        initialSpringVelocity: 0.8,
        options: .curveEaseInOut,
    ) {
        calling()
    } completion: { _ in
        completion?()
    }
}
