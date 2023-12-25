//
//  NoteNode.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation

public class NoteNode: Codable, Identifiable, Hashable, Equatable {
    public var id: Int { hashValue }
    // 主要展示的内容
    public let main: NoteID
    // 增加显示全部数据的按钮
    public let incompleteHeader: NoteID?

    // 所有需要显示的回复
    public let replies: [Replies]

    public init(main: NoteID, incompleteHeader: NoteID?, replies: [Replies]) {
        self.main = main
        self.incompleteHeader = incompleteHeader
        self.replies = replies
    }

    public static func == (lhs: NoteNode, rhs: NoteNode) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(main)
        hasher.combine(incompleteHeader)
        hasher.combine(replies)
    }
}

public extension NoteNode {
    class Replies: Codable, Identifiable, Hashable, Equatable {
        public var id: Int { hashValue }

        public var list: [NoteID]
        public var trimmed: Bool

        public init(list: [NoteID], trimmed: Bool) {
            assert(!list.isEmpty)
            self.list = list
            self.trimmed = trimmed
        }

        public static func == (lhs: Replies, rhs: Replies) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(list)
            hasher.combine(trimmed)
        }
    }
}

public extension NoteNode {
    func representedNotes() -> [NoteID] {
        var result = [main]
        result.append(contentsOf: replies.flatMap(\.list))
        return result
    }
}
