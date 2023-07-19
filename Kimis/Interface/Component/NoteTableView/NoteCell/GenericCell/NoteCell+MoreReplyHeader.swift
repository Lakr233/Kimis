//
//  NoteCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class MoreReplyHeaderCell: MoreHeaderCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            icon.image = .fluent(.arrow_maximize_vertical_filled)
            label.text = "Expend Collapsed Replies"
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let bounds = container.bounds
            let padding = IH.preferredPadding(usingWidth: bounds.width)
            let avatarSize = NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)
            label.frame = CGRect(
                x: padding + avatarSize + NotePreview.verticalSpacing,
                y: 0,
                width: 200,
                height: bounds.height
            )
            let fontSize = CGFloat(AppConfig.current.defaultNoteFontSize)
                + IH.preferredFontSizeOffset(usingWidth: bounds.width - 2 * padding)
            label.font = .systemFont(ofSize: fontSize, weight: .regular)
        }
    }
}
