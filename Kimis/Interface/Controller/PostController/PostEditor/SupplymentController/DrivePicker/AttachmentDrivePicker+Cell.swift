//
//  AttachmentDrivePicker.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/9.
//

import Combine
import Source
import UIKit

extension AttachmentDrivePicker {
    class AttachmentCell: UICollectionViewCell {
        static let cellId = "AttachmentCell"

        var attachment: Attachment? { didSet {
            if let attachment {
                preview.element = .init(with: attachment)
            } else {
                preview.element = nil
            }
        }}
        let preview = NoteAttachmentView.Preview()

        let selectionHint: UIImageView = {
            let view = UIImageView()
            view.image = .init(systemName: "checkmark.circle.fill")
            view.tintColor = .accent
            view.contentMode = .scaleAspectFit
            return view
        }()

        let sensitiveHint: UIImageView = {
            let view = UIImageView()
            view.image = .init(systemName: "eye.slash")
            view.tintColor = .systemPink
            view.contentMode = .scaleAspectFit
            return view
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.isUserInteractionEnabled = false

            contentView.layer.cornerRadius = IH.contentCornerRadius
            contentView.clipsToBounds = true
            contentView.addSubview(preview)

            preview.previewOption.disableSensitiveMask = true
            preview.previewOption.disableVideoPreview = true

            contentView.addSubview(sensitiveHint)
            contentView.addSubview(selectionHint)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            preview.frame = contentView.bounds

            let spacing: CGFloat = 4
            let hintSize: CGFloat = 32

            sensitiveHint.frame = CGRect(
                x: bounds.height - hintSize - spacing,
                y: bounds.width - hintSize - spacing,
                width: hintSize,
                height: hintSize
            )

            selectionHint.frame = CGRect(
                x: bounds.height - hintSize - spacing,
                y: spacing,
                width: hintSize,
                height: hintSize
            )
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            attachment = nil
            setSelection(false)
            sensitiveHint.isHidden = true
        }

        func load(_ attachment: Attachment) {
            self.attachment = attachment
            sensitiveHint.isHidden = !attachment.isSensitive
        }

        func setSelection(_ selected: Bool) {
            selectionHint.isHidden = !selected
        }
    }
}
