//
//  TextParser+Image.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/10.
//

import Foundation
import SubviewAttachingTextView
import UIKit

private let placeholder = UIImage(
    color: .gray.withAlphaComponent(0.5),
    size: .init(width: 50, height: 50),
)
.withRoundedCorners(radius: 8)

extension TextParser {
    class ImageAttachment: SubviewTextAttachment {
        private let provider: TextAttachedViewProvider

        init(image: UIImage, size: CGSize, tintColor: UIColor) {
            provider = ImageAttachmentProvider(image: image, size: size, tintColor: tintColor)
            super.init(viewProvider: provider)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private class ImageAttachmentProvider: TextAttachedViewProvider {
        let target: UIImage
        let tintColor: UIColor
        let size: CGSize

        init(image: UIImage, size: CGSize, tintColor: UIColor) {
            target = image
            self.size = size
            self.tintColor = tintColor
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func instantiateView(for _: SubviewTextAttachment, in _: SubviewAttachingTextViewBehavior) -> UIView {
            let view = UIImageView(image: target)
            view.contentMode = .scaleAspectFit
            view.layer.minificationFilter = .trilinear
            return view
        }

        func bounds(for _: SubviewTextAttachment, textContainer _: NSTextContainer?, proposedLineFragment _: CGRect, glyphPosition _: CGPoint) -> CGRect {
            CGRect(x: 0, y: -2, width: size.width, height: size.height)
        }
    }

    class RemoteImageAttachment: SubviewTextAttachment {
        let provider: TextAttachedViewProvider
        init(url: URL, size: CGSize, cornerRadius: CGFloat = 0) {
            provider = RemoteImageAttachmentProvider(url: url, size: size, cornerRadius: cornerRadius)
            super.init(viewProvider: provider)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private class RemoteImageAttachmentProvider: TextAttachedViewProvider {
        let url: URL
        let size: CGSize
        let cornerRadius: CGFloat

        init(url: URL, size: CGSize, cornerRadius: CGFloat = 0) {
            self.url = url
            self.size = size
            self.cornerRadius = cornerRadius
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func instantiateView(for _: SubviewTextAttachment, in _: SubviewAttachingTextViewBehavior) -> UIView {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.layer.minificationFilter = .trilinear
            view.sd_setImage(with: url, placeholderImage: placeholder, options: [], completed: nil)
            view.clipsToBounds = true
            view.layer.cornerRadius = cornerRadius
            return view
        }

        func bounds(for _: SubviewTextAttachment, textContainer _: NSTextContainer?, proposedLineFragment _: CGRect, glyphPosition _: CGPoint) -> CGRect {
            .init(x: 0, y: -2, width: size.width, height: size.height)
        }
    }
}
