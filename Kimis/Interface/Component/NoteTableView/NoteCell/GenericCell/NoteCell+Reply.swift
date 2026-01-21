//
//  NoteCell+Reply.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class ReplyCell: NoteCell {
        let preview = NotePreview()

        let connectorUp = UIView()
        let connectorDown = UIView()

        var snapshot: Snapshot?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            container.addSubview(preview)

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

            container.addSubview(connectorUp)
            container.addSubview(connectorDown)
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
            preview.snapshot = snapshot?.noteSnapshot
            container.isHidden = snapshot == nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let snapshot {
                preview.frame = snapshot.previewRect
                connectorUp.frame = snapshot.connectorUpRect
                connectorDown.frame = snapshot.connectorDownRect
            } else {
                preview.frame = .zero
                connectorUp.frame = .zero
                connectorDown.frame = .zero
            }
        }
    }
}

extension NoteCell.ReplyCell {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var previewRect: CGRect = .zero
        var connectorUpRect: CGRect = .zero
        var connectorDownRect: CGRect = .zero
        var noteSnapshot: NotePreview.Snapshot = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(previewRect)
            hasher.combine(connectorUpRect)
            hasher.combine(connectorDownRect)
            hasher.combine(noteSnapshot)
        }
    }
}

extension NoteCell.ReplyCell.Snapshot {
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
        let contentWidth = width - padding * 2
        let avatarSize = IH.preferredAvatarSizeOffset(usingWidth: width) + NotePreview.defaultAvatarSize
        let noteSnapshot = NotePreview.Snapshot(usingWidth: contentWidth, avatarSize: avatarSize, context: context)
        let previewRect = CGRect(
            x: padding,
            y: padding,
            width: contentWidth,
            height: noteSnapshot.height,
        )
        let height = noteSnapshot.height + padding + (context.disablePaddingAfter ? 0 : padding)

        let connectorX = padding + avatarSize / 2 - IH.connectorWidth / 2

        let connectorUpFrame = CGRect(
            x: connectorX,
            y: 0,
            width: IH.connectorWidth,
            height: padding + noteSnapshot.avatarRect.minY - 4,
        )
        let connectorDownFrame = CGRect(
            x: connectorX,
            y: padding + noteSnapshot.avatarRect.maxY + 4,
            width: IH.connectorWidth,
            height: height - (padding + noteSnapshot.avatarRect.maxY + 4) + 1,
        )

        self.width = width
        self.height = height
        self.previewRect = previewRect
        connectorUpRect = connectorUpFrame
        connectorDownRect = connectorDownFrame
        self.noteSnapshot = noteSnapshot
    }

    func invalidate() {
        width = 0
        height = 0
        previewRect = .zero
        connectorUpRect = .zero
        connectorDownRect = .zero
        noteSnapshot = .init()
    }
}
