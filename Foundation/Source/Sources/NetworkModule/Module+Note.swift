//
//  Network+NMNote.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/5.
//

import Foundation

public struct NMNote: Codable {
    public var id: String
    public var createdAt: String
    public var cw: String?
    public var text: String?
    public var userId: String
    public var user: NMUserLite
    public var visibility: String?
    public var emojis: [NMEmoji]?
    public var renoteCount: Int?
    public var repliesCount: Int?
    public var reactions: [String: Int]?
    public var myReaction: String?
    public var uri: String?
    public var url: String?
    public var fileIds: [String]?
    public var channelId: String?
    public var files: [NMDriveFile]?
    public var localOnly: Bool?
    public var tags: [String]?
    public var isHidden: Bool?
    public var renoteId: String?
    public var visibleUserIds: [String]?
    public var replyId: String?
    public var mentions: [String]?
    public var poll: NMNotePoll?
}

public struct NMNoteReaction: Codable {
    public var id: String
    public var createdAt: String
    public var user: NMUserLite
    public var type: String
}

public struct NMNotePoll: Codable {
    public var multiple: Bool
    public var expiresAt: String?
    public var choices: [NMNotePollChoice]
}

public struct NMNotePollChoice: Codable {
    public var text: String
    public var votes: Int
    public var isVoted: Bool
}
