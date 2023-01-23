//
//  Network+NMUserLite.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/1.
//

import Foundation

public struct NMUserLite: Codable {
    public var id: String
    public var name: String?
    public var username: String
    public var host: String?
    public var avatarUrl: String?
    public var avatarBlurhash: String?
    public var avatarColor: String?
    public var emojis: [NMEmoji]?
    public var onlineStatus: String?
    public var isAdmin: Bool?
    public var isBot: Bool?
    public var isModerator: Bool?
    public var isCat: Bool?

    public var instance: NMInstance?
}

public struct NMUserDetails: Codable {
    public var id: String

    public var name: String?
    public var username: String
    public var host: String?

    public var avatarUrl: String?
    public var avatarBlurhash: String?

    public var isAdmin: Bool?
    public var isModerator: Bool?
    public var isBot: Bool?
    public var isCat: Bool?

    public var instance: NMInstance?
    public var emojis: [NMEmoji]?

    public var onlineStatus: String?

    public var url: String?
    public var uri: String?

    public var createdAt: String

    public var bannerUrl: String?
    public var bannerBlurhash: String?

    public var description: String?
    public var location: String?
    public var birthday: String?
    public var fields: [NMFields]?

    public var followersCount: Int?
    public var followingCount: Int?
    public var notesCount: Int?

    public var pinnedNoteIds: [String]?
    public var pinnedNotes: [NMNote]?

    public var ffVisibility: String?

    public var isLocked: Bool?

    public var isFollowing: Bool?
    public var isFollowed: Bool?

    public var hasPendingFollowRequestFromYou: Bool?
    public var hasPendingFollowRequestToYou: Bool?

    public var isBlocking: Bool?
    public var isBlocked: Bool?

    public var isMuted: Bool?

    public var mutedWords: [[String]]?
}

public struct NMFields: Codable {
    public var name: String
    public var value: String
}
