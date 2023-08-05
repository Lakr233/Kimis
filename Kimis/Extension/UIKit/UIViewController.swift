//
//  UIViewController.swift
//  mTale
//
//  Created by Lakr Aream on 2022/3/31.
//

import UIKit

extension UIViewController {
    func platformSetup() {
        view.clipsToBounds = false
        view.backgroundColor = .platformBackground
        popoverPresentationController?.backgroundColor = .platformBackground
        hideKeyboardWhenTappedAround()
    }

    func presentSheetToMainWindow() {
        prepareModalSheet()
        UIWindow.topController?.present(self, animated: true, completion: nil)
    }

    func prepareModalSheet(style: UIModalPresentationStyle? = nil, preferredSize: CGSize? = CGSize(width: 720, height: 480)) {
        modalTransitionStyle = .coverVertical
        if let style {
            modalPresentationStyle = style
        } else {
            modalPresentationStyle = .fullScreen
        }
        if let preferredSize {
            preferredContentSize = preferredSize
        }
        isModalInPresentation = true
    }

    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    var topBarHeight: CGFloat {
        (
            view
                .window?
                .windowScene?
                .statusBarManager?
                .statusBarFrame
                .height ?? 0.0
        ) + (
            navigationController?
                .navigationBar
                .frame
                .height ?? 0.0
        )
    }

    func present(next: UIViewController) {
        guard let presenter = topMostController else { return }
        if let navigator = presenter.navigationController,
           !(next is UINavigationController),
           !(next is UIAlertController),
           !(next is UIActivityViewController)
        {
            CATransaction.begin()
            navigator.pushViewController(next, animated: true)
            CATransaction.commit()
        } else {
            presenter.present(next, animated: true, completion: nil)
        }
    }

    var topMostController: UIViewController? {
        var result: UIViewController? = self
        while true {
            if let next = result?.presentedViewController,
               !next.isBeingDismissed,
               next as? UISearchController == nil
            {
                result = next
                continue
            }
            if let tabBar = result as? UITabBarController,
               let next = tabBar.selectedViewController
            {
                result = next
                continue
            }
            if let split = result as? UISplitViewController,
               let next = split.viewControllers.last
            {
                result = next
                continue
            }
            if let navigator = result as? UINavigationController,
               let next = navigator.viewControllers.last
            {
                result = next
                continue
            }
            if let target = result as? LLSplitController {
                result = target.leftController
                continue
            }
            if let target = result as? LLNavController {
                result = target.associatedNavigationController
                continue
            }
            if let target = result as? RootController,
               let newTarget = target.controller
            {
                result = newTarget
                continue
            }
            if let target = result as? SideBarController {
                result = target.contentController
                continue
            }
            break
        }
        return result
    }

    func moveViewWithKeyboard(notification: NSNotification, keyboardWillShow: Bool, increasingHeight: (CGFloat) -> Void) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardHeight = keyboardSize.height
        let keyboardDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let keyboardCurve = UIView.AnimationCurve(rawValue: notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! Int)!

        let targetHeight: CGFloat = keyboardWillShow ? keyboardHeight : 0
        increasingHeight(targetHeight)

        let animator = UIViewPropertyAnimator(duration: keyboardDuration, curve: keyboardCurve) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
}
