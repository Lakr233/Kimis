//
//  NoteCell+ContextRender.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/21.
//

import Foundation

extension NoteCell.Context {
    func renderLayout(usingWidth width: CGFloat) {
        // this is not thread safe impl, setting snapshot = nil may result empty cell
        let containerWidth = IH.containerWidth(usingWidth: width)
        switch kind {
        case .abstract: break
        case .separator: break
        case .progress: break
        case .moreHeader: break
        case .moreReply: break
        case .moreReplyPadded: break
        case .full:
            let shot = NoteCell.FullCell.Snapshot(usingWidth: containerWidth, context: self)
            snapshot = shot
            cellHeight = shot.height
        case .main, .pinned:
            let shot = NoteCell.MainCell.Snapshot(usingWidth: containerWidth, context: self)
            snapshot = shot
            cellHeight = shot.height
        case .reply:
            let shot = NoteCell.ReplyCell.Snapshot(usingWidth: containerWidth, context: self)
            snapshot = shot
            cellHeight = shot.height
        case .replyPadded:
            let shot = NoteCell.ReplyPaddedCell.Snapshot(usingWidth: containerWidth, context: self)
            snapshot = shot
            cellHeight = shot.height
        }
    }
}
