//
//  UIView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

private let kDefaultShadowColor = UIColor(light: .gray, dark: .black)

extension UIView {
    func dropShadow(ofColor color: UIColor = kDefaultShadowColor,
                    radius: CGFloat = 4,
                    offset: CGSize = .zero,
                    opacity: Float = 0.16)
    {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
        clipsToBounds = false
    }

    func puddingAnimate() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withUIKitAnimation(duration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: {
            withUIKitAnimation(duration: 0.1) {
                self.transform = .identity
            }
        }
    }

    func debugFrame() {
        var list: [UIView] = [self]
        while !list.isEmpty {
            let view = list.removeFirst()
            view.layer.borderColor = UIColor.randomAsPudding.cgColor
            view.layer.borderWidth = 1
            list.append(contentsOf: view.subviews)
        }
    }
}
