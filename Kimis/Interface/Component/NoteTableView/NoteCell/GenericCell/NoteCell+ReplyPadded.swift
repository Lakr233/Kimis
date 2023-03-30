//
//  NoteCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class ReplyPaddedCell: NoteCell {
        let preview = NotePreview()

        let connectorUp = UIView()
        let connectorDown = UIView()
        let connectorPass = UIView()
        var connectorAttach: LeftBottomCurveLine!

        var snapshot: Snapshot?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            connectorAttach = .init(lineWidth: IH.connectorWidth, lineRadius: 30, lineColor: .separator)

            container.addSubview(connectorUp)
            container.addSubview(connectorDown)
            container.addSubview(connectorPass)
            container.addSubview(connectorAttach)
            container.addSubview(preview)

            connectorPass.backgroundColor = .separator
            connectorUp.layer.maskedCorners = [
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
            connectorUp.layer.cornerRadius = IH.connectorWidth / 2
            connectorUp.backgroundColor = .separator
            connectorDown.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
            ]
            connectorDown.layer.cornerRadius = IH.connectorWidth / 2
            connectorDown.backgroundColor = .separator
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            snapshot = nil
            preview.snapshot = nil
        }

        override func load(data: NoteCell.Context) {
            super.load(data: data)
            if let snapshot = data.snapshot as? Snapshot {
                self.snapshot = snapshot
                preview.snapshot = snapshot.noteSnapshot
            }
            connectorUp.isHidden = !data.connectors.contains(.up)
            connectorDown.isHidden = !data.connectors.contains(.down)
            connectorPass.isHidden = !data.connectors.contains(.pass)
            connectorAttach.isHidden = !data.connectors.contains(.attach)
            container.isHidden = snapshot == nil
            preview.snapshot = snapshot?.noteSnapshot
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let snapshot {
                preview.frame = snapshot.previewRect
                connectorUp.frame = snapshot.connectorUpRect
                connectorDown.frame = snapshot.connectorDownRect
                connectorPass.frame = snapshot.connectorPassRect
                connectorAttach.frame = snapshot.connectorAttachRect
            } else {
                preview.frame = .zero
                connectorUp.frame = .zero
                connectorDown.frame = .zero
                connectorPass.frame = .zero
                connectorAttach.frame = .zero
            }
        }
    }
}

extension NoteCell.ReplyPaddedCell {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var previewRect: CGRect = .zero
        var connectorUpRect: CGRect = .zero
        var connectorDownRect: CGRect = .zero
        var connectorPassRect: CGRect = .zero
        var connectorAttachRect: CGRect = .zero

        var noteSnapshot: NotePreview.Snapshot = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(previewRect)
            hasher.combine(connectorUpRect)
            hasher.combine(connectorDownRect)
            hasher.combine(connectorPassRect)
            hasher.combine(connectorAttachRect)
            hasher.combine(noteSnapshot)
        }
    }
}

extension NoteCell.ReplyPaddedCell.Snapshot {
    convenience init(usingWidth width: CGFloat, context: NoteCell.Context) {
        self.init()
        render(usingWidth: width, context: context)
    }

    func render(usingWidth width: CGFloat, context: NoteCell.Context) {
        renderHint = context
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let context = renderHint as? NoteCell.Context else {
            assertionFailure()
            return
        }

        let padding = IH.preferredPadding(usingWidth: width)
        let avatarSize = NotePreview.smallerAvatarSize
        let rightShift = padding + (NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)) / 2
        let contentWidth = width - padding * 2 - rightShift
        let noteSnapshot = NotePreview.Snapshot(usingWidth: contentWidth, avatarSize: avatarSize, context: context)
        let previewRect = CGRect(
            x: rightShift + padding,
            y: padding,
            width: contentWidth,
            height: noteSnapshot.height
        )
        let height = noteSnapshot.height + padding + (context.disablePaddingAfter ? 0 : padding)

        let connectorUpFrame = CGRect(
            x: rightShift + padding + avatarSize / 2 - IH.connectorWidth / 2,
            y: 0,
            width: IH.connectorWidth,
            height: padding + noteSnapshot.avatarRect.minY - 4
        )
        let connectorDownFrame = CGRect(
            x: padding + rightShift + avatarSize / 2 - IH.connectorWidth / 2,
            y: padding + noteSnapshot.avatarRect.maxY + 4,
            width: IH.connectorWidth,
            height: height - (padding + noteSnapshot.avatarRect.maxY + 4) + 1
        )

        let connectorX = padding + (NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)) / 2 - IH.connectorWidth / 2
        let connectorPassRect = CGRect(
            x: connectorX,
            y: 0,
            width: IH.connectorWidth,
            height: height + 1
        )
        let connectorAttachRect = CGRect(
            x: connectorX,
            y: 0,
            width: previewRect.minX - connectorX,
            height: padding + noteSnapshot.avatarRect.midY + IH.connectorWidth / 2
        )

        self.width = width
        self.height = height
        self.previewRect = previewRect
        connectorUpRect = connectorUpFrame
        connectorDownRect = connectorDownFrame
        self.connectorPassRect = connectorPassRect
        self.connectorAttachRect = connectorAttachRect
        self.noteSnapshot = noteSnapshot
    }

    func invalidate() {
        width = 0
        height = 0
        previewRect = .zero
        connectorUpRect = .zero
        connectorDownRect = .zero
        connectorPassRect = .zero
        connectorAttachRect = .zero
        noteSnapshot = .init()
    }
}
