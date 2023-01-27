//
//  Network+NMUserLite.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/1.
//

import BetterCodable
import Foundation

public struct NMUserLite: Codable {
    public var id: String
    @LossyOptional public var name: String?
    public var username: String
    @LossyOptional public var host: String?
    @LossyOptional public var avatarUrl: String?
    @LossyOptional public var avatarBlurhash: String?
    @LossyOptional public var avatarColor: String?
    @LossyOptional public var emojis: [NMEmoji]?
    @LossyOptional public var onlineStatus: String?
    @LossyOptional public var isAdmin: Bool?
    @LossyOptional public var isBot: Bool?
    @LossyOptional public var isModerator: Bool?
    @LossyOptional public var isCat: Bool?

    @LossyOptional public var instance: NMInstance?
}

public struct NMUserDetails: Codable {
    public var id: String

    @LossyOptional public var name: String?
    public var username: String
    @LossyOptional public var host: String?

    @LossyOptional public var avatarUrl: String?
    @LossyOptional public var avatarBlurhash: String?

    @LossyOptional public var isAdmin: Bool?
    @LossyOptional public var isModerator: Bool?
    @LossyOptional public var isBot: Bool?
    @LossyOptional public var isCat: Bool?

    @LossyOptional public var instance: NMInstance?
    @LossyOptional public var emojis: [NMEmoji]?

    @LossyOptional public var onlineStatus: String?

    @LossyOptional public var url: String?
    @LossyOptional public var uri: String?

    public var createdAt: String

    @LossyOptional public var bannerUrl: String?
    @LossyOptional public var bannerBlurhash: String?

    @LossyOptional public var description: String?
    @LossyOptional public var location: String?
    @LossyOptional public var birthday: String?
    @LossyOptional public var fields: [NMFields]?

    @LossyOptional public var followersCount: Int?
    @LossyOptional public var followingCount: Int?
    @LossyOptional public var notesCount: Int?

    @LossyOptional public var pinnedNoteIds: [String]?
    @LossyOptional public var pinnedNotes: [NMNote]?

    @LossyOptional public var ffVisibility: String?

    @LossyOptional public var isLocked: Bool?

    @LossyOptional public var isFollowing: Bool?
    @LossyOptional public var isFollowed: Bool?

    @LossyOptional public var hasPendingFollowRequestFromYou: Bool?
    @LossyOptional public var hasPendingFollowRequestToYou: Bool?

    @LossyOptional public var isBlocking: Bool?
    @LossyOptional public var isBlocked: Bool?

    @LossyOptional public var isMuted: Bool?

    @LossyOptional public var mutedWords: [[String]]?
}

public struct NMFields: Codable {
    public var name: String
    public var value: String
}
