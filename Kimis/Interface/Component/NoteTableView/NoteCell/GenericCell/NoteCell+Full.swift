//
//  NoteCell+Full.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class FullCell: NoteCell {
        let noteView = NoteView()
        var snapshot: Snapshot?

        let connectorUp = UIView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            container.addSubview(noteView)
            connectorUp.layer.maskedCorners = [
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
            connectorUp.layer.cornerRadius = IH.connectorWidth / 2
            connectorUp.backgroundColor = .separator
            container.addSubview(connectorUp)
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            snapshot = nil
            noteView.snapshot = nil
        }

        override func load(data: NoteCell.Context) {
            super.load(data: data)
            if let snapshot = data.snapshot as? Snapshot {
                self.snapshot = snapshot
                noteView.snapshot = snapshot.noteSnapshot
            }
            connectorUp.isHidden = !data.connectors.contains(.up)
            container.isHidden = snapshot == nil
            noteView.snapshot = snapshot?.noteSnapshot
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let snapshot {
                noteView.frame = snapshot.previewRect
                connectorUp.frame = snapshot.connectorUpRect
            } else {
                noteView.frame = .zero
            }
        }
    }
}

extension NoteCell.FullCell {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var previewRect: CGRect = .zero
        var connectorUpRect: CGRect = .zero
        var noteSnapshot: NoteView.Snapshot = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(previewRect)
            hasher.combine(connectorUpRect)
            hasher.combine(noteSnapshot)
        }
    }
}

extension NoteCell.FullCell.Snapshot {
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
        let noteSnapshot = NoteView.Snapshot(usingWidth: contentWidth, avatarSize: avatarSize, context: context)
        let previewRect = CGRect(
            x: padding,
            y: padding,
            width: contentWidth,
            height: noteSnapshot.height,
        )
        let height = noteSnapshot.height + padding * 2

        let connectorX = padding + avatarSize / 2 - IH.connectorWidth / 2

        let connectorUpFrame = CGRect(
            x: connectorX,
            y: 0,
            width: IH.connectorWidth,
            height: padding - 4,
        )

        self.width = width
        self.height = height
        self.previewRect = previewRect
        connectorUpRect = connectorUpFrame
        self.noteSnapshot = noteSnapshot
    }

    func invalidate() {
        width = 0
        height = 0
        previewRect = .zero
        connectorUpRect = .zero
        noteSnapshot = .init()
    }
}
