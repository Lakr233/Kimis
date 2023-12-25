//
//  NoteTreeResolver+Struct.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/4.
//

import Foundation

extension NoteTreeResolver {
    enum NoteType: String {
        case regular // note, renote
        case reply

        static func choose(note: Note) -> NoteType {
            // note 可能同时包含 reply 和 renote
            // 如果包含 reply 则视为 reply
            // 回复一个 renote 也许是合法的？
            if note.replyId != nil {
                return .reply
            }
            return .regular
        }
    }
}
