//
//  ReactionStrip+MoreView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

extension ReactionStrip {
    class MoreView: UIView {
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

        init() {
            super.init(frame: .zero)
            layer.cornerRadius = IH.contentMiniItemCornerRadius
            backgroundColor = UIColor.gray.withAlphaComponent(0.1)
            addSubview(label)
            label.text = "..."
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
