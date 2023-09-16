//
//  NoteAttachmentView+Preview.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import Combine
import SafariServices
import UIKit

private let kDefaultPreviewIcon = UIImage(systemName: "doc.text.fill")

extension NoteAttachmentView {
    class Preview: UIView {
        var element: NoteAttachmentView.Elemet? { didSet { updateElementPropertiesIfNeeded() } }
        private var currentElement: NoteAttachmentView.Elemet?

        struct PreviewOption {
            var disableFilename: Bool = false
            var disableSensitiveMask: Bool = false
            var disableVideoPreview: Bool = false
        }

        var previewOption: PreviewOption = .init() {
            didSet { setNeedsLayout() }
        }

        let imageView = ImageView()
        let videoView = VideoView()

        var attachmentIcon: UIImage? {
            guard let element else { return kDefaultPreviewIcon }
            if element.contentType.lowercased().hasPrefix("image/") {
                return UIImage(systemName: "photo")
            }
            if element.contentType.lowercased().hasPrefix("video/") {
                return UIImage(systemName: "play.rectangle")
            }
            if element.contentType.lowercased().hasPrefix("audio/") {
                return UIImage(systemName: "waveform")
            }
            if element.contentType.lowercased().hasPrefix("text/") {
                return UIImage(systemName: "doc.text")
            }
            return kDefaultPreviewIcon
        }

        let attachmentIconView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()

        let label: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            label.textAlignment = .center
            label.numberOfLines = 1
            label.minimumScaleFactor = 0.5
            label.adjustsFontSizeToFitWidth = true
            label.textColor = .accent
            return label
        }()

        let openButton = UIButton()

        init() {
            super.init(frame: .zero)
            backgroundColor = .systemBlackAndWhite.withAlphaComponent(0.05)
            imageView.option.previewEnabled = true
            addSubview(imageView)
            addSubview(videoView)
            addSubview(attachmentIconView)
            addSubview(label)
            addSubview(openButton)
            openButton.addTarget(self, action: #selector(openInSafari), for: .touchUpInside)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let this = self // Ambiguous use of 'bounds'
            let bounds = this.bounds
            imageView.frame = bounds
            videoView.frame = bounds
            openButton.frame = bounds
            let size = CGSize(width: 30, height: 30)
            attachmentIconView.frame = CGRect(
                x: (bounds.width - size.width) / 2,
                y: (bounds.height - size.height) / 2,
                width: size.width,
                height: size.height
            )
            let labelHeight = bounds.height - attachmentIconView.frame.maxY
            label.frame = CGRect(
                x: 0,
                y: attachmentIconView.frame.maxY,
                width: bounds.width,
                height: labelHeight
            )
            .inset(by: .init(horizontal: 8, vertical: 8))
            label.isHidden = previewOption.disableFilename
        }

        func updateElementPropertiesIfNeeded() {
            guard currentElement != element else {
                return
            }
            currentElement = element
            for view in subviews {
                view.isHidden = true
            }
            label.text = ""
            if let element {
                activatePreview(forElement: element)
            } else {
                imageView.loadImage(with: nil)
            }
        }

        func activatePreview(forElement element: Elemet) {
            if element.contentType.lowercased().hasPrefix("image/") {
                imageView.isHidden = false
                imageView.loadImage(with: .init(
                    url: element.url.absoluteString,
                    blurHash: element.previewBlur,
                    sensitive: element.sensitive && !previewOption.disableSensitiveMask
                ))
                return
            }
            if !previewOption.disableVideoPreview,
               element.contentType.lowercased().hasPrefix("video/")
            {
                videoView.isHidden = false
                videoView.videoUrl = element.url
                return
            }

            // default preview
            attachmentIconView.isHidden = false
            label.isHidden = false
            openButton.isHidden = false
            label.text = element.name
            attachmentIconView.image = attachmentIcon
        }

        @objc func openInSafari() {
            guard let element else { return }
            let safari = SFSafariViewController(url: element.url)
            parentViewController?.present(safari, animated: true)
        }
    }
}
