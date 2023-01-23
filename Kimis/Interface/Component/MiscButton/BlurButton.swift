//
//  BlurButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/4.
//

import UIKit

class BlurButton: UIView {
    let blur: UIVisualEffectView
    let button = UIButton()

    init(systemIcon: String, tintColor: UIColor, effect: UIVisualEffect) {
        blur = .init(effect: effect)

        super.init(frame: .zero)

        clipsToBounds = true
        addSubview(blur)
        addSubview(button)

        button.setImage(UIImage(systemName: systemIcon), for: .normal)
        button.imageView?.tintColor = tintColor
        button.imageView?.contentMode = .scaleAspectFit
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        button.frame = bounds.inset(by: .init(inset: 2))
    }
}
