//
//  ReactionStrip+EmojiView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

extension ReactionStrip {
    class EmojiView: UIView {
        let emoji: String
        let count: Int

        let label: UILabel = {
            let view = UILabel()
            view.textAlignment = .center
            view.clipsToBounds = true
            view.layer.masksToBounds = true
            view.numberOfLines = 1
            view.minimumScaleFactor = 0.5
            view.adjustsFontSizeToFitWidth = true
            view.font = .systemFont(ofSize: 16, weight: .regular)
            return view
        }()

        init(emoji: String, count: Int, highlight: Bool) {
            self.emoji = emoji
            self.count = count
            super.init(frame: .zero)
            layer.cornerRadius = IH.contentMiniItemCornerRadius
            backgroundColor = highlight
                ? UIColor.accent.withAlphaComponent(0.1)
                : UIColor.gray.withAlphaComponent(0.1)
            addSubview(label)
            label.text = "\(emoji) x\(count)"
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            label.frame = bounds
        }
    }
}
