//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/27.
//

import Foundation
import Module
import ModuleBridge
import Network
import NetworkModule

public extension Source.NetworkWrapper {
    struct NoteState: Codable {
        public var isFavorited: Bool
        public var isMutedThread: Bool

        public init(isFavorited: Bool = false, isMutedThread: Bool = false) {
            self.isFavorited = isFavorited
            self.isMutedThread = isMutedThread
        }

        static func populateFromDic(dic: [String: Any]) -> Self {
            var build = Self()
            if let isFavorited = dic["isFavorited"] as? Bool, isFavorited {
                build.isFavorited = isFavorited
            }
            if let isMutedThread = dic["isMutedThread"] as? Bool, isMutedThread {
                build.isMutedThread = isMutedThread
            }
            return build
        }
    }
}

public extension Source.NetworkWrapper {
    func requestTimeline(
        endpoint: String,
        limit: Int = 50,
        sinceId: String? = nil,
        untilId: String? = nil
    ) -> [NoteID] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForUserTimeline(
            using: endpoint,
            limit: limit,
            sinceDate: nil,
            untilDate: nil,
            sinceId: sinceId,
            untilId: untilId
        )
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result.map(\.id)
    }

    func requestNoteSearch(
        query: String,
        limit: Int = 20,
        untilId: NoteID? = nil
    ) -> [NoteID] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForNoteSearch(
            query: query,
            limit: limit,
            untilId: untilId
        )
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result.map(\.id)
    }

    @discardableResult
    func requestNote(withID noteId: NoteID?) -> Note? {
        guard let ctx, let noteId else { return nil }
        let result = ctx.network.requestForNote(with: noteId)
        ctx.spider.spidering(result)
        if let note = result {
            return .converting(note)
        }
        return nil
    }

//    @discardableResult
    func requestNoteDelete(withId noteId: NoteID) {
        guard let ctx else { return }
        ctx.network.requestForNoteDelete(with: noteId)
        ctx.notes.delete(noteId)
        ctx.timeline.deleteNote(noteId: noteId)
    }

    @discardableResult
    func requestNoteState(withID noteId: NoteID?) -> NoteState {
        guard let ctx, let noteId else { return .init() }
        let object = ctx.network.requestForNoteState(with: noteId)
        return .populateFromDic(dic: object)
    }

    @discardableResult
    func requestNoteReplies(withID noteId: NoteID?) -> [Note] {
        guard let ctx, let noteId else { return [] }
        let result = ctx.network.requestForReplies(toNoteWithId: noteId)
        // exclude original notes, since those notes may be non-detailed
        ctx.spider.spidering(result.extracted.filter { $0.id != noteId })
        ctx.spider.spidering(result.result.filter { $0.id != noteId })
        return result.result.compactMap { .converting($0) }
    }

    @discardableResult
    func requestNoteReaction(reactionIdentifier emoji: String?, forNote noteId: NoteID?) -> Note? {
        guard let ctx, let noteId else { return nil }
        let result: NMNote?
        if let emoji {
            result = ctx.network.requestForReactionCreate(with: noteId, reaction: emoji)
        } else {
            result = ctx.network.requestForReactionDelete(with: noteId)
        }
        ctx.spider.spidering(result)
        if let result { return .converting(result) }
        return nil
    }

    @discardableResult
    func requestForUserNotes(userHandler: String, type: Network.UserNoteFetchType, untilId: String?) -> [NoteID] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForUserNotes(
            userId: userHandler,
            type: type,
            sinceId: nil,
            untilId: untilId,
            sinceDate: nil,
            untilDate: nil
        )
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result.map(\.id)
    }

    @discardableResult
    func requestNotePollVote(forNote noteId: NoteID, choiceIndex: Int) -> Note? {
        guard let ctx else { return nil }
        let result: NMNote?
        result = ctx.network.requestForPollVote(with: noteId, choice: choiceIndex)
        ctx.spider.spidering(result)
        if let result { return .converting(result) }
        return nil
    }

    @discardableResult
    func requestNoteCreate(forPost post: Post, renote: NoteID?, reply: NoteID?) -> Note? {
        guard let ctx else { return nil }
        guard let postData = NMPost.converting(post) else { return nil }
        guard let result = ctx.network.requestForNoteCreate(
            with: postData,
            renoteId: renote,
            replyId: reply
        ) else {
            return nil
        }
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        if let data = result.result {
            return .converting(data)
        }
        return nil
    }

    @discardableResult
    func requestNoteAddFavorite(note: NoteID) -> NoteState? {
        guard let ctx else { return nil }
        defer { DispatchQueue.global().async {
            ctx.bookmark.reloadBookmark(force: true)
        } }
        ctx.network.requestForNoteFavoriteCreate(with: note)
        let check = requestNoteState(withID: note)
        return check.isFavorited ? check : nil
    }

    @discardableResult
    func requestNoteRemoveFavorite(note: NoteID) -> NoteState? {
        guard let ctx else { return nil }
        defer { DispatchQueue.global().async {
            ctx.bookmark.reloadBookmark(force: true)
        } }
        ctx.network.requestForNoteFavoriteDelete(with: note)
        let check = requestNoteState(withID: note)
        return !check.isFavorited ? check : nil
    }
}
