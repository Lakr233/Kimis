//
//  ReactionStrip+ImageView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import Source
import UIKit

extension ReactionStrip {
    class ImageView: ElementBaseView {
        let url: URL
        let count: Int

        let image: UIImageView = {
            let view = UIImageView()
            view.layer.magnificationFilter = .trilinear
            view.contentMode = .scaleAspectFit
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
            countView.text = "x\(count)"
            emojiContainer.addSubview(image)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            image.frame = emojiContainer.bounds
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
