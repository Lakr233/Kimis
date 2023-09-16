//
//  NoteCell+MoreReplyPadded.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class MoreReplyPaddedCell: NoteCell {
        var connectorAttach: LeftBottomCurveLine!
        let connectorBall = UIView()
        let connectorDown = UIView()
        let connectorPass = UIView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            connectorAttach = .init(lineWidth: IH.connectorWidth, lineRadius: 30, lineColor: .separator)

            container.addSubview(connectorBall)
            container.addSubview(connectorAttach)
            container.addSubview(connectorDown)
            container.addSubview(connectorPass)

            connectorBall.backgroundColor = .separator
            connectorDown.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
            ]
            connectorDown.layer.cornerRadius = IH.connectorWidth / 2
            connectorDown.backgroundColor = .separator
            connectorPass.backgroundColor = .separator
        }

        override func load(data: NoteCell.Context) {
            super.load(data: data)
            connectorAttach.isHidden = !data.connectors.contains(.attach)
            connectorDown.isHidden = !data.connectors.contains(.down)
            connectorPass.isHidden = !data.connectors.contains(.pass)
            connectorBall.isHidden = connectorAttach.isHidden && connectorDown.isHidden && connectorPass.isHidden
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let bounds = container.bounds
            let padding = IH.preferredPadding(usingWidth: bounds.width)
            let rightShift = padding + (NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)) / 2
            let ballSize: CGFloat = 4
            let avatarSize = NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)
            let smallerAvatarSize = NotePreview.smallerAvatarSize
            connectorBall.frame = CGRect(
                x: padding + rightShift + smallerAvatarSize / 2 - ballSize / 2,
                y: bounds.midY - ballSize / 2,
                width: ballSize,
                height: ballSize
            )
            connectorBall.layer.cornerRadius = ballSize / 2
            connectorDown.frame = CGRect(
                x: connectorBall.frame.midX - IH.connectorWidth / 2,
                y: connectorBall.frame.maxY + 4,
                width: IH.connectorWidth,
                height: bounds.height - connectorBall.frame.maxY - 4 + 1
            )
            connectorPass.frame = CGRect(
                x: padding + avatarSize / 2 - IH.connectorWidth / 2,
                y: 0,
                width: IH.connectorWidth,
                height: bounds.height + 1
            )
            connectorAttach.frame = CGRect(
                x: padding + avatarSize / 2 - IH.connectorWidth / 2,
                y: 0,
                width: connectorBall.frame.minX - 4 - connectorPass.frame.minX,
                height: bounds.height / 2 + IH.connectorWidth / 2
            )
        }
    }
}
