//
//  ChidoriAnimationController.swift
//  Chidori
//
//  Created by Christian Selig on 2021-02-15.
//

import UIKit

class ChidoriAnimationController: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning {
    enum AnimationControllerType { case presentation, dismissal }

    let type: AnimationControllerType

    var animatorForCurrentSession: UIViewPropertyAnimator?

    weak var context: UIViewControllerContextTransitioning?

    init(type: AnimationControllerType) {
        self.type = type
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.4
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        context = transitionContext
        animateTransition(using: transitionContext)
    }

    func cancelTransition() {
        guard let context,
              let animator = animatorForCurrentSession else { return }

        // Cancel the current transition
        context.cancelInteractiveTransition()

        // Play the animation in reverse
        animator.isReversed = true
        animator.startAnimation()

        if type == .presentation {
            if let presentingViewController = context.viewController(forKey: .from) {
                presentingViewController.view.tintAdjustmentMode = .automatic
            } else {
                preconditionFailure("Presenting view controller should be accessible")
            }
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let interruptableAnimator = interruptibleAnimator(using: transitionContext)

        if type == .presentation {
            if let chidoriMenu: ChidoriMenu = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? ChidoriMenu {
                transitionContext.containerView.addSubview(chidoriMenu.view)
            }

            if let presentingViewController = transitionContext.viewController(forKey: .from) {
                presentingViewController.view.tintAdjustmentMode = .dimmed
            } else {
                preconditionFailure("Presenting view controller should be accessible")
            }
        } else {
            if let presentingViewController = transitionContext.viewController(forKey: .to) {
                presentingViewController.view.tintAdjustmentMode = .automatic
            }
        }

        interruptableAnimator.startAnimation()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let animatorForCurrentSession {
            return animatorForCurrentSession
        }

        let propertyAnimator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 0.8)
        propertyAnimator.isInterruptible = true
        propertyAnimator.isUserInteractionEnabled = true

        let isPresenting = type == .presentation

        guard let chidoriMenu: ChidoriMenu = (isPresenting ? transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) : transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)) as? ChidoriMenu else {
            preconditionFailure("Menu should be accessible")
        }

        let finalFrame = transitionContext.finalFrame(for: chidoriMenu)
        chidoriMenu.view.frame = finalFrame

        // Rather than moving the origin of the view's frame for the animation (which is causing issues with jumpiness), just translate the view temporarily.
        // Accomplish this by finding out how far we have to translate it by creating a reference point from the center of the menu we're moving, and compare that to the center point of where we're moving it to (we're moving it to a specific coordinate, not a frame, so the center point is the same as the coordinate)
        let translationRequired = calculateTranslationRequired(forChidoriMenuFrame: finalFrame, toDesiredPoint: chidoriMenu.summonPoint)

        let initialAlpha: CGFloat = isPresenting ? 0.0 : 1.0
        let finalAlpha: CGFloat = isPresenting ? 1.0 : 0.0

        let translatedAndScaledTransform = CGAffineTransform(translationX: translationRequired.dx, y: translationRequired.dy).scaledBy(x: 0.25, y: 0.05)
        let initialTransform = isPresenting ? translatedAndScaledTransform : .identity
        let finalTransform = isPresenting ? .identity : translatedAndScaledTransform

        chidoriMenu.view.transform = initialTransform
        chidoriMenu.view.alpha = initialAlpha

        // Animate! 🪄
        propertyAnimator.addAnimations {
            chidoriMenu.view.transform = finalTransform
            chidoriMenu.view.alpha = finalAlpha
        }

        propertyAnimator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.animatorForCurrentSession = nil
        }

        animatorForCurrentSession = propertyAnimator
        return propertyAnimator
    }

    private func calculateTranslationRequired(forChidoriMenuFrame chidoriMenuFrame: CGRect, toDesiredPoint desiredPoint: CGPoint) -> CGVector {
        let centerPointOfMenuView = CGPoint(x: chidoriMenuFrame.origin.x + (chidoriMenuFrame.width / 2.0), y: chidoriMenuFrame.origin.y + (chidoriMenuFrame.height / 2.0))
        let translationRequired = CGVector(dx: desiredPoint.x - centerPointOfMenuView.x, dy: desiredPoint.y - centerPointOfMenuView.y)
        return translationRequired
    }
}
