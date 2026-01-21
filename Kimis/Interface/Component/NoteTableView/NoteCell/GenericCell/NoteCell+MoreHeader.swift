//
//  NoteCell+MoreHeader.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class MoreHeaderCell: NoteCell {
        let label = UILabel()
        let icon = UIImageView()
        let connectorUp = UIView()
        let connectorBall = UIView()
        let connectorDown = UIView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            container.addSubview(connectorUp)
            container.addSubview(connectorBall)
            container.addSubview(connectorDown)
            container.addSubview(label)
            container.addSubview(icon)

            icon.tintColor = .accent
            icon.contentMode = .scaleAspectFit
            icon.image = UIImage.fluent(.arrow_collapse_all_filled)
            label.text = L10n.text("Load More Replies")
            label.textColor = .accent
            label.textAlignment = .left
            label.numberOfLines = 1
            label.minimumScaleFactor = 0.5
            label.adjustsFontSizeToFitWidth = true

            connectorUp.layer.maskedCorners = [
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
            connectorUp.layer.cornerRadius = IH.connectorWidth / 2
            connectorUp.backgroundColor = .separator

            connectorBall.backgroundColor = .separator
            connectorDown.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
            ]
            connectorDown.layer.cornerRadius = IH.connectorWidth / 2
            connectorDown.backgroundColor = .separator
        }

        override func load(data: NoteCell.Context) {
            super.load(data: data)
            connectorUp.isHidden = !data.connectors.contains(.up)
            connectorDown.isHidden = !data.connectors.contains(.down)
            connectorBall.isHidden = connectorUp.isHidden && connectorDown.isHidden
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            label.font = .systemFont(ofSize: CGFloat(AppConfig.current.defaultNoteFontSize), weight: .regular)

            let bounds = container.bounds
            let padding = IH.preferredPadding(usingWidth: bounds.width)
            let avatarSize = NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)
            connectorBall.frame = CGRect(
                x: padding + avatarSize / 2 - IH.connectorWidth / 2,
                y: bounds.midY - IH.connectorWidth / 2,
                width: IH.connectorWidth,
                height: IH.connectorWidth,
            )
            connectorBall.layer.cornerRadius = IH.connectorWidth / 2
            connectorUp.frame = CGRect(
                x: padding + avatarSize / 2 - IH.connectorWidth / 2,
                y: 0,
                width: IH.connectorWidth,
                height: connectorBall.frame.minY - 4,
            )
            connectorDown.frame = CGRect(
                x: padding + avatarSize / 2 - IH.connectorWidth / 2,
                y: connectorBall.frame.maxY + 4,
                width: IH.connectorWidth,
                height: bounds.height - connectorBall.frame.maxY - 4 + 1,
            )

            let iconSize = CGSize(width: 16, height: 16)
            icon.frame = CGRect(
                x: padding + avatarSize - iconSize.width,
                y: bounds.midY - iconSize.height / 2,
                width: iconSize.width,
                height: iconSize.height,
            )

            let horizontalSpacing = padding
            label.frame = CGRect(
                x: padding + avatarSize + horizontalSpacing,
                y: 0,
                width: 200,
                height: bounds.height,
            )
        }
    }
}
