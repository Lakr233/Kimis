//
//  PostEditorAttachmentView+Cell.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/12.
//

import Combine
import Source
import UIKit

extension PostEditorAttachmentView {
    class AttachmentCell: UICollectionViewCell, UIContextMenuInteractionDelegate {
        static let cellId = "AttachmentCell"

        weak var source: Source? = Account.shared.source

        var attachment: Attachment? { didSet {
            if let attachment {
                preview.element = .init(with: attachment)
            } else {
                preview.element = nil
            }
        }}
        var indexPath: IndexPath?
        weak var representedPost: Post?
        let preview = NoteAttachmentView.Preview()
        let sensitiveBackground = UIView()
        let sensitiveIcon = UIImageView()

        let button = UIButton()

        override init(frame: CGRect) {
            super.init(frame: frame)

            preview.previewOption.disableSensitiveMask = true
            preview.previewOption.disableVideoPreview = true
            preview.isUserInteractionEnabled = false

            let interaction = UIContextMenuInteraction(delegate: self)
            button.addInteraction(interaction)
            contentView.addSubview(button)
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

            button.addSubview(preview)

            contentView.addSubview(sensitiveBackground)
            sensitiveBackground.backgroundColor = .black
            sensitiveBackground.alpha = 0.5
            sensitiveBackground.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            sensitiveIcon.image = .init(systemName: "exclamationmark.triangle.fill")
            sensitiveIcon.tintColor = .white
            sensitiveIcon.contentMode = .scaleAspectFit
            contentView.addSubview(sensitiveIcon)
            sensitiveIcon.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(24)
            }
            sensitiveBackground.isUserInteractionEnabled = false
            sensitiveIcon.isUserInteractionEnabled = false

            preview.clipsToBounds = true
            preview.layer.cornerRadius = IH.contentCornerRadius
            sensitiveBackground.clipsToBounds = true
            sensitiveBackground.layer.cornerRadius = IH.contentCornerRadius
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            preview.frame = contentView.bounds
            button.frame = contentView.bounds
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            attachment = nil
            indexPath = nil
            representedPost = nil
            sensitiveBackground.isHidden = true
            sensitiveIcon.isHidden = true
        }

        func load(_ attachment: Attachment, atIndexPath indexPath: IndexPath, editOnPost post: Post) {
            self.attachment = attachment
            self.indexPath = indexPath
            representedPost = post
            if attachment.isSensitive {
                sensitiveIcon.isHidden = false
                sensitiveBackground.isHidden = false
            } else {
                sensitiveIcon.isHidden = true
                sensitiveBackground.isHidden = true
            }
        }

        func createMenu() -> UIMenu? {
            guard let indexPath, let post = representedPost else {
                return nil
            }
            var menus: [UIAction] = []
            if attachment?.isSensitive ?? false {
                menus.append(UIAction(title: "Unmark Sensitive", image: UIImage(systemName: "eye"), handler: { _ in
                    self.updateAttachment(isSensitive: false)
                }))
            } else {
                menus.append(UIAction(title: "Mark Sensitive", image: UIImage(systemName: "eye.slash"), handler: { _ in
                    self.updateAttachment(isSensitive: true)
                }))
            }
            menus.append(
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in
                    post.attachments.remove(at: indexPath.row)
                }),
            )
            return UIMenu(children: menus)
        }

        func updateAttachment(isSensitive: Bool) {
            guard let source,
                  let post = representedPost,
                  let attachment
            else { return }
            let alert = UIAlertController(title: "⏳", message: "Updating this attachment", preferredStyle: .alert)
            parentViewController?.present(alert, animated: true)
            DispatchQueue.global().async {
                defer { withMainActor {
                    alert.dismiss(animated: true)
                } }
                guard let result = source.req.requestDriveFileUpdate(
                    fileId: attachment.attachId,
                    isSensitive: isSensitive,
                ) else { return }
                post.attachments = post.attachments.map { attach in
                    if attach.attachId == result.attachId {
                        return result
                    }
                    return attach
                }
            }
        }

        func createContextMenuConfig() -> UIContextMenuConfiguration? {
            guard let menu = createMenu(), let attachment else {
                return nil
            }
            return .init(identifier: attachment.attachId as NSString) {
                nil
            } actionProvider: { _ in
                menu
            }
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration _: UIContextMenuConfiguration) -> UITargetedPreview? {
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .platformBackground
            let preview = UITargetedPreview(view: preview, parameters: parameters)
            return preview
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            createContextMenuConfig()
        }

        @objc func buttonTapped() {
            button.presentMenu()
        }
    }
}
