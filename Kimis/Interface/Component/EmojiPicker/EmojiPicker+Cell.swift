//
//  EmojiPicker+Cell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/5.
//

import SDWebImage
import UIKit

extension EmojiPickerView {
    class EmojiPickerCell: UICollectionViewCell {
        let imageView = UIImageView()
        let label = UILabel()
        let loadingIndicator = UIActivityIndicatorView()

        static let cellId = "wiki.qaq.emoji.cell"

        override init(frame: CGRect) {
            super.init(frame: frame)
            imageView.contentMode = .scaleAspectFit
            imageView.layer.minificationFilter = .trilinear
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            label.font = .systemFont(ofSize: 32)
            label.textAlignment = .center
            contentView.addSubview(label)
            contentView.addSubview(loadingIndicator)
            contentView.addSubview(imageView)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            imageView.frame = bounds
            loadingIndicator.frame = bounds
            label.frame = bounds
        }

        override func prepareForReuse() {
            label.text = ""
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = nil
            loadingIndicator.stopAnimating()
        }

        func apply(item: EmojiElement) {
            if item.emoji.emoji.hasPrefix(":"),
               item.emoji.emoji.hasSuffix(":"),
               let url = URL(string: item.emoji.description)
            {
                loadingIndicator.startAnimating()
                imageView.sd_setImage(with: url) { [weak self] img, _, _, _ in
                    if img != nil {
                        self?.loadingIndicator.stopAnimating()
                    }
                }
                return
            } else {
                label.text = item.emoji.emoji
            }
        }
    }

    class EmojiPickerSectionHeader: UICollectionReusableView {
        let label = UILabel()
        let effect: UIView

        static let headerId = "wiki.qaq.EmojiPickerSectionHeader"

        override init(frame: CGRect) {
            let blur = UIBlurEffect(style: .regular)
            let effect = UIVisualEffectView(effect: blur)
            self.effect = effect

            label.textAlignment = .left
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.alpha = 0.5

            super.init(frame: frame)

            addSubview(effect)
            addSubview(label)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            label.frame = bounds.inset(by: UIEdgeInsets(horizontal: 4, vertical: 0))
            effect.frame = bounds.inset(by: UIEdgeInsets(horizontal: -50, vertical: 0))
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func prepareForReuse() {
            label.text = ""
        }
    }
}
