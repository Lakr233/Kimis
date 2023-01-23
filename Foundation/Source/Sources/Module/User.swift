//
//  User.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation
import SwiftDate

public typealias UserID = String

public class User: Codable, Identifiable, Hashable, Equatable {
    public var id: String { userId }

    public var userId: String
    public var name: String
    public var username: String
    public var host: String

    public var instance: Instance?

    public var absoluteUsername: String {
        "@\(username)@\(host)"
    }

    public init(userId: String = "", name: String = "", username: String = "", host: String = "", instance: Instance? = nil, avatarUrl: String? = nil, avatarBlurHash: String? = nil, isAdmin: Bool = false, isBot: Bool = false, isModerator: Bool = false, isCat: Bool = false) {
        self.userId = userId
        self.name = name
        self.username = username
        self.host = host
        self.instance = instance
        self.avatarUrl = avatarUrl
        self.avatarBlurHash = avatarBlurHash
        self.isAdmin = isAdmin
        self.isBot = isBot
        self.isModerator = isModerator
        self.isCat = isCat
    }

    public var avatarUrl: String?
    public var avatarBlurHash: String?

    public var isAdmin: Bool = false
    public var isBot: Bool = false
    public var isModerator: Bool = false
    public var isCat: Bool = false

    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(name)
        hasher.combine(username)
        hasher.combine(host)
        hasher.combine(instance)
        hasher.combine(avatarUrl)
        hasher.combine(avatarBlurHash)
        hasher.combine(isAdmin)
        hasher.combine(isBot)
        hasher.combine(isModerator)
        hasher.combine(isCat)
    }
}

public class UserProfile: Codable, Identifiable, Hashable, Equatable {
    public var id: String { userId }

    public var userId: String

    public var name: String
    public var username: String
    public var host: String

    public var absoluteUsername: String {
        "@\(username)@\(host)"
    }

    public var avatarUrl: String?
    public var avatarBlurhash: String?

    public var isAdmin: Bool
    public var isModerator: Bool
    public var isBot: Bool
    public var isCat: Bool

    public var instance: Instance?

    public var online: Bool
    /*
     case 'online': return i18n.ts.online;
     case 'active': return i18n.ts.active;
     case 'offline': return i18n.ts.offline;
     case 'unknown': return i18n.ts.unknown;
     */

    public var url: String
    public var uri: String

    public var createdAt: Date

    public var bannerUrl: String?
    public var bannerBlurhash: String?

    public var description: String
    public var location: String?
    public var birthday: String?

    public var fields: [FieldElement]

    public var followersCount: Int
    public var followingCount: Int
    public var notesCount: Int

    public var pinnedNoteIds: [String]

    public var publiclyVisible: Bool
    /* == "public"
     <option value="public">{{ i18n.ts._ffVisibility.public }}</option>
     <option value="followers">{{ i18n.ts._ffVisibility.followers }}</option>
     <option value="private">{{ i18n.ts._ffVisibility.private }}</option>
     */

    public var isLocked: Bool // private profile

    public var isFollowing: Bool
    public var isFollowed: Bool

    public var hasPendingFollowRequestFromYou: Bool
    public var hasPendingFollowRequestToYou: Bool

    public var isBlocking: Bool
    public var isBlocked: Bool

    public var isMuted: Bool

    public var mutedWords: [String]

    public init(userId: String = "", name: String = "", username: String = "", host: String = "", avatarUrl: String? = nil, avatarBlurhash: String? = nil, isAdmin: Bool = false, isModerator: Bool = false, isBot: Bool = false, isCat: Bool = false, instance: Instance? = nil, online: Bool = false, url: String = "", uri: String = "", createdAt: Date = Date(timeIntervalSince1970: 0), bannerUrl: String? = nil, bannerBlurhash: String? = nil, description: String = "", fields: [FieldElement] = [], location: String? = nil, birthday: String? = nil, followersCount: Int = 0, followingCount: Int = 0, notesCount: Int = 0, pinnedNoteIds: [String] = [], publiclyVisible: Bool = false, isLocked: Bool = false, isFollowing: Bool = false, isFollowed: Bool = false, hasPendingFollowRequestFromYou: Bool = false, hasPendingFollowRequestToYou: Bool = false, isBlocking: Bool = false, isBlocked: Bool = false, isMuted: Bool = false, mutedWords: [String] = []) {
        self.userId = userId
        self.name = name
        self.username = username
        self.host = host
        self.avatarUrl = avatarUrl
        self.avatarBlurhash = avatarBlurhash
        self.isAdmin = isAdmin
        self.isModerator = isModerator
        self.isBot = isBot
        self.isCat = isCat
        self.instance = instance
        self.online = online
        self.url = url
        self.uri = uri
        self.createdAt = createdAt
        self.bannerUrl = bannerUrl
        self.bannerBlurhash = bannerBlurhash
        self.description = description
        self.fields = fields
        self.location = location
        self.birthday = birthday
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.notesCount = notesCount
        self.pinnedNoteIds = pinnedNoteIds
        self.publiclyVisible = publiclyVisible
        self.isLocked = isLocked
        self.isFollowing = isFollowing
        self.isFollowed = isFollowed
        self.hasPendingFollowRequestFromYou = hasPendingFollowRequestFromYou
        self.hasPendingFollowRequestToYou = hasPendingFollowRequestToYou
        self.isBlocking = isBlocking
        self.isBlocked = isBlocked
        self.isMuted = isMuted
        self.mutedWords = mutedWords
    }

    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(name)
        hasher.combine(username)
        hasher.combine(host)
        hasher.combine(avatarUrl)
        hasher.combine(avatarBlurhash)
        hasher.combine(isAdmin)
        hasher.combine(isModerator)
        hasher.combine(isBot)
        hasher.combine(isCat)
        hasher.combine(instance)
        hasher.combine(online)
        hasher.combine(url)
        hasher.combine(uri)
        hasher.combine(createdAt)
        hasher.combine(bannerUrl)
        hasher.combine(bannerBlurhash)
        hasher.combine(description)
        hasher.combine(location)
        hasher.combine(birthday)
        hasher.combine(fields)
        hasher.combine(followersCount)
        hasher.combine(followingCount)
        hasher.combine(notesCount)
        hasher.combine(pinnedNoteIds)
        hasher.combine(publiclyVisible)
        hasher.combine(isLocked)
        hasher.combine(isFollowing)
        hasher.combine(isFollowed)
        hasher.combine(hasPendingFollowRequestFromYou)
        hasher.combine(hasPendingFollowRequestToYou)
        hasher.combine(isBlocking)
        hasher.combine(isBlocked)
        hasher.combine(isMuted)
        hasher.combine(mutedWords)
    }

    public class FieldElement: Codable, Identifiable, Hashable, Equatable {
        public var id: UUID = .init()

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }

        public var name: String
        public var value: String

        public static func == (lhs: FieldElement, rhs: FieldElement) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(value)
        }
    }
}
