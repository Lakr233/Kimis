//
//  ReactionStrip+Element.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import Foundation

extension ReactionStrip {
    struct ReactionElement: Hashable, Equatable {
        let noteId: NoteID

        let text: String?
        let url: URL?
        let count: Int
        let isUserReaction: Bool

        var validated: Bool {
            if text == nil { url != nil }
            else { url == nil }
        }

        let representImageReaction: String?

        init(
            noteId: NoteID,
            text: String? = nil,
            url: URL? = nil,
            count: Int,
            highlight: Bool,
            representReaction: String? = nil,
        ) {
            self.noteId = noteId
            self.text = text
            self.url = url
            self.count = count
            isUserReaction = highlight
            representImageReaction = representReaction
        }
    }
}
