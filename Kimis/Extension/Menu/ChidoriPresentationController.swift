//
//  ChidoriPresentationController.swift
//  Chidori
//
//  Created by Christian Selig on 2021-02-15.
//

import UIKit

protocol ChidoriPresentationControllerDelegate: NSObjectProtocol {
    func didTapOverlayView(_ chidoriPresentationController: ChidoriPresentationController)
}

class ChidoriPresentationController: UIPresentationController {
    let darkOverlayView: UIView = .init()
    let tapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

    weak var transitionDelegate: ChidoriPresentationControllerDelegate?

    // MARK: - Animation Lifecycle

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let containerView else {
            assertionFailure("Container view should be present at this point")
            return
        }

        darkOverlayView.translatesAutoresizingMaskIntoConstraints = false
        darkOverlayView.isUserInteractionEnabled = true
        darkOverlayView.isAccessibilityElement = true
        darkOverlayView.accessibilityTraits = .button
        darkOverlayView.accessibilityHint = "Dismiss context menu"

        // This is the only part where we depart from the iOS design, I find the background doesn't darken enough with the iOS one to provide enough contrast/attention, so add a bit more (the haptic-touch context menu variant blurs the background, which this one does not do)
        darkOverlayView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)

        darkOverlayView.alpha = 0.0
        presentingViewController.view.tintAdjustmentMode = .dimmed
        containerView.addSubview(darkOverlayView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: darkOverlayView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: darkOverlayView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: darkOverlayView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: darkOverlayView.bottomAnchor),
        ])

        tapGestureRecognizer.addTarget(self, action: #selector(tappedDarkOverlayView(tapGestureRecognizer:)))
        darkOverlayView.addGestureRecognizer(tapGestureRecognizer)

        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { (_: UIViewControllerTransitionCoordinatorContext) in
                self.darkOverlayView.alpha = 1.0
            }, completion: nil)
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        presentingViewController.view.tintAdjustmentMode = .automatic

        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { (_: UIViewControllerTransitionCoordinatorContext) in
                self.darkOverlayView.alpha = 0.0
            }, completion: nil)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            darkOverlayView.removeFromSuperview()
        }
    }

    // MARK: - Layouting

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let chidoriMenu = presentedViewController as? ChidoriMenu else {
            preconditionFailure("Should only be used with ChidoriMenu")
        }

        let height = min(chidoriMenu.height(), maxHeight())
        let menuSize = CGSize(width: ChidoriMenu.width, height: height)
        let originatingPoint = calculateOriginatingPoint(summonPoint: chidoriMenu.summonPoint, menuSize: menuSize)

        return CGRect(origin: originatingPoint, size: menuSize)
    }

    func maxHeight() -> CGFloat {
        guard let containerView else {
            assertionFailure("Container view should be present at this point")
            return 0.0
        }

        // Approximately inline with iOS version
        if containerView.bounds.height < 1000 {
            return containerView.bounds.height * 0.75
        } else {
            return containerView.bounds.height * 0.9
        }
    }

    private func calculateOriginatingPoint(summonPoint: CGPoint, menuSize: CGSize) -> CGPoint {
        guard let containerView else { return .zero }

        let requiredSidePadding: CGFloat = 10.0
        let offsetFromFinger: CGFloat = 10.0

        let x: CGFloat = {
            // iOS seems to try to shove it to the left of the touch point (if possible) to prevent your finger obscuring the titles
            let attemptedDistanceFromTouchPoint: CGFloat = 180.0

            let leftShiftedPoint = summonPoint.x - attemptedDistanceFromTouchPoint
            let lowestPermissableXPosition = requiredSidePadding + containerView.safeAreaInsets.left
            let rightMostPermissableXPosition = containerView.bounds.width - requiredSidePadding - containerView.safeAreaInsets.right - menuSize.width
            return min(rightMostPermissableXPosition, max(leftShiftedPoint, lowestPermissableXPosition))
        }()

        let y: CGFloat = {
            // Check if we have enough room to place it below the touch point
            if summonPoint.y + menuSize.height + offsetFromFinger + requiredSidePadding < containerView.bounds.height - containerView.safeAreaInsets.bottom {
                return summonPoint.y + offsetFromFinger
            } else {
                // If not, iOS tries to keep as much in the bottom half of the screen as possible (to be closer to where the thumb normally is, presumably) so mimic that
                return containerView.bounds.height - requiredSidePadding - containerView.safeAreaInsets.bottom - menuSize.height
            }
        }()

        return CGPoint(x: x, y: y)
    }

    // MARK: - Target Action

    @objc private func tappedDarkOverlayView(tapGestureRecognizer _: UITapGestureRecognizer) {
        transitionDelegate?.didTapOverlayView(self)
    }
}
