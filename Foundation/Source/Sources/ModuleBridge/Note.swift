//
//  Note.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation
import Module
import NetworkModule
import SwiftDate

public extension Note {
    static func converting(_ note: NMNote) -> Note? {
        var url: URL?
        if let __url = note.url, let _url = URL(string: __url) {
            url = _url
        }
        guard let date = note.createdAt.toISODate(nil, region: nil)?.date else {
            return nil
        }
        guard let visibility = note.visibility else {
            return nil
        }
        var instance: Instance?
        if let getInstance = note.user.instance {
            instance = .converting(getInstance)
        }
        let attachs: [Attachment] = note.files?.compactMap { Attachment.converting($0) } ?? []
        var poll: Poll?
        if let _poll = note.poll {
            let totalVote = Double(_poll.choices.map(\.votes).reduce(0, +))
            poll = .init(
                multiple: _poll.multiple,
                expiresAt: _poll.expiresAt?.toISODate(nil, region: nil)?.date,
                choices: _poll.choices.map { .init(
                    text: $0.text,
                    votes: $0.votes,
                    isVoted: $0.isVoted,
                    percent: totalVote > 0 ? Double($0.votes) / totalVote : 0
                ) }
            )
        }
        return .init(
            noteId: note.id,
            url: url,
            date: date,
            contentWarning: note.cw,
            text: note.text ?? "",
            attachments: attachs,
            reactions: note.reactions ?? [:],
            visibility: visibility,
            userId: note.userId,
            userInstance: instance,
            userReaction: note.myReaction ?? "",
            renoteId: note.renoteId,
            replyId: note.replyId,
            tags: note.tags ?? [],
            mentions: note.mentions ?? [],
            poll: poll
        )
    }
}
