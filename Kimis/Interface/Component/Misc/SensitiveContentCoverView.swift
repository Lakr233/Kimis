//
//  SensitiveContentCoverView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

class SensitiveContentCoverView: UIView {
    let button = UIButton()
    let blockButton = UIButton()

    let blurBackground: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemThickMaterial)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    static let iconSize = CGSize(width: 30, height: 30)
    let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlackAndWhite
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.text = "Sensitive Content"
        label.textColor = .systemBlackAndWhite
        label.font = .rounded(ofSize: CGFloat(AppConfig.current.defaultNoteFontSize), weight: .regular)
        label.numberOfLines = 2
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    init() {
        super.init(frame: .zero)
        addSubview(blurBackground)
        addSubview(icon)
        addSubview(label)
        addSubview(blockButton)
        addSubview(button)
        button.setTitleColor(.accent, for: .normal)
        let underline: [NSAttributedString.Key: Any] = [
            .font: UIFont.rounded(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.accent,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        let text = NSMutableAttributedString(string: "Unlock", attributes: underline)
        button.setAttributedTitle(text, for: .normal)
        button.addTarget(self, action: #selector(hide), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let this = self
        let bounds = this.bounds
        blurBackground.frame = bounds.inset(by: .init(inset: -2))
        blockButton.frame = bounds
        icon.frame = CGRect(
            x: bounds.width / 2 - Self.iconSize.width / 2,
            y: bounds.height / 2 - Self.iconSize.height / 2 - 20,
            width: Self.iconSize.width,
            height: Self.iconSize.height
        )
        let labelWidth = bounds.width - 10
        label.frame = CGRect(x: (bounds.width - labelWidth) / 2, y: icon.frame.maxY + 2, width: labelWidth, height: 24)

        button.sizeToFit()
        button.frame = CGRect(x: bounds.width / 2 - 50, y: label.frame.maxY, width: 100, height: 20)
    }

    @objc func show() {
        isHidden = false
    }

    @objc func hide() {
        isHidden = true
    }
}
