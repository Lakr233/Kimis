//
//  NetworkWrapper+Hashtag.swift
//
//
//  Created by Lakr Aream on 2022/11/27.
//

import Foundation

public extension Source.NetworkWrapper {
    @discardableResult
    func requestHashtagTrending() -> [Trending]? {
        guard let ctx else { return nil }
        let result = ctx.network.requestForHashtagsTrending()
        ctx.spider.spidering(result)
        if let trending = result {
            return trending
                .compactMap { .converting($0) }
                .filter { !ctx.isTextMuted(text: $0.tag) }
        }
        return nil
    }

    @discardableResult
    func requestHashtagList(tag: String, until: NoteID?) -> [Note] {
        guard let ctx else { return [] }
        guard let result = ctx.network.requestForHashtagsNotes(tag: tag, limit: 16, untilId: until) else {
            return []
        }
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result
            .compactMap { Note.converting($0) }
            .filter { !ctx.isNoteMuted(noteId: $0.noteId) }
    }
}
