//
//  UIButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/7.
//

import UIKit

class TapAreaEnlargedButton: UIButton {
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        var enlarge: CGFloat = 14
        if frame.width > 50 || frame.height > 50 { enlarge = 0 }
        return bounds.insetBy(dx: -enlarge, dy: -enlarge).contains(point)
    }
}

public extension UIButton {
    func presentMenu() {
        guard !presentOldWay() else { return }

        guard let menu = retrieveMenu() else { return }
        guard let presenter = parentViewController else { return }

        let origin = convert(bounds.center, to: window)
        let chidoriMenu = ChidoriMenu(menu: menu, summonPoint: origin)
        chidoriMenu.delegate = MenuDelegate.shared
        presenter.present(chidoriMenu, animated: true, completion: nil)
    }

    private func presentOldWay() -> Bool {
        guard let interaction = interactions.first,
              let data = Data(base64Encoded: "X3ByZXNlbnRNZW51QXRMb2NhdGlvbjo="),
              let str = String(data: data, encoding: .utf8)
        else {
            return false
        }
        let selector = NSSelectorFromString(str)
        guard interaction.responds(to: selector) else {
            return false
        }
        interaction.perform(selector, with: CGPoint.zero)
        return true
    }
}

private class MenuDelegate: NSObject, ChidoriDelegate {
    static let shared = MenuDelegate()

    func didSelectAction(_ action: UIAction) {
        guard action.responds(to: NSSelectorFromString("handler")),
              let handler = action.value(forKey: "_handler")
        else { return }
        typealias ActionBlock = @convention(block) (UIAction) -> Void
        let blockPtr = UnsafeRawPointer(Unmanaged<AnyObject>.passUnretained(handler as AnyObject).toOpaque())
        let block = unsafeBitCast(blockPtr, to: ActionBlock.self)
        withMainActor(delay: 0.5) { block(action) }
    }
}

extension UIButton {
    private func retrieveMenu() -> UIMenu? {
        for interaction in interactions {
            if let menuInteraction = interaction as? UIContextMenuInteraction,
               let menuConfig = menuInteraction.delegate?.contextMenuInteraction(
                   menuInteraction,
                   configurationForMenuAtLocation: .zero
               ),
               let menu = menuConfig.retrieveMenu()
            {
                return menu
            }
        }
        if let menuConfig = contextMenuInteraction(
            .init(delegate: JustGiveMeMenu.shared),
            configurationForMenuAtLocation: .zero
        ), let menu = menuConfig.retrieveMenu() {
            return menu
        }
        return nil
    }
}

private class JustGiveMeMenu: NSObject, UIContextMenuInteractionDelegate {
    static let shared = JustGiveMeMenu()

    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        nil
    }
}

private extension UIContextMenuConfiguration {
    func retrieveMenu() -> UIMenu? {
        guard responds(to: NSSelectorFromString("actionProvider")),
              let actionProvider = value(forKey: "_actionProvider")
        else { return nil }
        typealias ActionProviderBlock = @convention(block) ([UIMenuElement]) -> (UIMenu?)
        let blockPtr = UnsafeRawPointer(Unmanaged<AnyObject>.passUnretained(actionProvider as AnyObject).toOpaque())
        let handler = unsafeBitCast(blockPtr, to: ActionProviderBlock.self)
        return handler([])
    }
}
