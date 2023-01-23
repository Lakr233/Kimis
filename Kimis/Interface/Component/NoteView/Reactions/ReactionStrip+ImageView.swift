//
//  ReactionStrip+ImageView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

extension ReactionStrip {
    class ImageView: UIView {
        let url: URL
        let count: Int

        let image: UIImageView = {
            let view = UIImageView()
            view.layer.magnificationFilter = .trilinear
            view.contentMode = .scaleAspectFit
            return view
        }()

        let label: UILabel = {
            let view = UILabel()
            view.textAlignment = .center
            view.layer.cornerRadius = 6
            view.clipsToBounds = true
            view.layer.masksToBounds = true
            view.numberOfLines = 1
            view.minimumScaleFactor = 0.5
            view.adjustsFontSizeToFitWidth = true
            view.font = .rounded(ofSize: 16, weight: .regular)
            return view
        }()

        init(url: URL, count: Int, highlight: Bool) {
            self.url = url
            self.count = count
            super.init(frame: .zero)
            layer.cornerRadius = IH.contentMiniItemCornerRadius
            backgroundColor = highlight
                ? UIColor.accent.withAlphaComponent(0.1)
                : UIColor.gray.withAlphaComponent(0.1)
            addSubview(label)
            addSubview(image)
            label.text = "x\(count)"
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let this = self
            let bounds = this.bounds

            label.frame = CGRect(
                x: bounds.width / 2,
                y: 0,
                width: bounds.width / 2,
                height: bounds.height
            )
            image.frame = CGRect(
                x: 0,
                y: 0,
                width: bounds.width / 2,
                height: bounds.height
            ).inset(by: .init(inset: 4))
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            image.sd_setImage(with: url)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
