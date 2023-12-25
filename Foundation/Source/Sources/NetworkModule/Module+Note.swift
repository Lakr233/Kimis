//
//  Module+Note.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/5.
//

import BetterCodable
import Foundation

public struct NMNote: Codable {
    public var id: String
    public var createdAt: String
    @LossyOptional public var cw: String?
    @LossyOptional public var text: String?
    public var userId: String
    public var user: NMUserLite
    @LossyOptional public var visibility: String?
    @LossyOptional public var emojis: [NMEmoji]?
    @LossyOptional public var renoteCount: Int?
    @LossyOptional public var repliesCount: Int?
    @LossyOptional public var reactions: [String: Int]?
    @LossyOptional public var myReaction: String?
    @LossyOptional public var uri: String?
    @LossyOptional public var url: String?
    @LossyOptional public var fileIds: [String]?
    @LossyOptional public var channelId: String?
    @LossyOptional public var files: [NMDriveFile]?
    @LossyOptional public var localOnly: Bool?
    @LossyOptional public var tags: [String]?
    @LossyOptional public var isHidden: Bool?
    @LossyOptional public var renoteId: String?
    @LossyOptional public var visibleUserIds: [String]?
    @LossyOptional public var replyId: String?
    @LossyOptional public var mentions: [String]?
    @LossyOptional public var poll: NMNotePoll?
}

public struct NMNoteReaction: Codable {
    public var id: String
    public var createdAt: String
    public var user: NMUserLite
    public var type: String
}

public struct NMNotePoll: Codable {
    public var multiple: Bool
    @LossyOptional public var expiresAt: String?
    public var choices: [NMNotePollChoice]
}

public struct NMNotePollChoice: Codable {
    public var text: String
    public var votes: Int
    public var isVoted: Bool
}
