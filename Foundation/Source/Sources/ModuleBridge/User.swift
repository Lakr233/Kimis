//
//  User.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation
import Module
import NetworkModule
import SwiftDate

public extension User {
    static func converting(_ user: NMUserLite, defaultHost: String) -> User {
        var name = user.name ?? ""
        if name.isEmpty {
            var username = user.username
            if username.hasPrefix("@") { username.removeFirst() }
            if username.contains("@") {
                name = username.components(separatedBy: "@").first ?? ""
            }
        }
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { name = user.username }
        var instance: Instance?
        if let ins = user.instance { instance = Instance.converting(ins) }
        return User(
            userId: user.id,
            name: name,
            username: user.username,
            host: user.host ?? defaultHost,
            instance: instance,
            avatarUrl: user.avatarUrl,
            avatarBlurHash: user.avatarBlurhash,
            isAdmin: user.isAdmin ?? false,
            isBot: user.isBot ?? false,
            isModerator: user.isModerator ?? false,
            isCat: user.isCat ?? false
        )
    }

    static func converting(_ profile: UserProfile) -> User {
        User(
            userId: profile.userId,
            name: profile.name,
            username: profile.username,
            host: profile.host,
            avatarUrl: profile.avatarUrl,
            avatarBlurHash: profile.avatarBlurhash,
            isAdmin: profile.isAdmin,
            isBot: profile.isBot,
            isModerator: profile.isModerator,
            isCat: profile.isCat
        )
    }
}

public extension UserProfile {
    static func converting(_ user: User?) -> UserProfile? {
        guard let user else { return nil }
        return UserProfile(
            userId: user.userId,
            name: user.name,
            username: user.username,
            host: user.host,
            avatarUrl: user.avatarUrl,
            avatarBlurhash: user.avatarBlurHash,
            isAdmin: user.isAdmin,
            isModerator: user.isModerator,
            isBot: user.isBot,
            isCat: user.isCat
        )
    }

    static func converting(_ userDetails: NMUserDetails?, defaultHost: String) -> UserProfile? {
        guard let userDetails else { return nil }
        guard let date = userDetails.createdAt.toISODate(nil, region: nil)?.date else {
            return nil
        }
        var instanceBuilder: Instance?
        if let instance = userDetails.instance {
            instanceBuilder = Instance.converting(instance)
        }
        var fields: [FieldElement] = []
        for item in userDetails.fields ?? [] {
            let element = FieldElement(name: item.name, value: item.value)
            fields.append(element)
        }
        return UserProfile(
            userId: userDetails.id,
            name: userDetails.name ?? userDetails.username,
            username: userDetails.username,
            host: userDetails.host ?? defaultHost,
            avatarUrl: userDetails.avatarUrl,
            avatarBlurhash: userDetails.avatarBlurhash,
            isAdmin: userDetails.isAdmin ?? false,
            isModerator: userDetails.isModerator ?? false,
            isBot: userDetails.isBot ?? false,
            isCat: userDetails.isCat ?? false,
            instance: instanceBuilder,
            online: userDetails.onlineStatus == "online" || userDetails.onlineStatus == "active",
            url: userDetails.url ?? "https://\(defaultHost)/@\(userDetails.name ?? userDetails.username)",
            uri: userDetails.uri ?? "https://\(defaultHost)/users/@\(userDetails.id)",
            createdAt: date,
            bannerUrl: userDetails.bannerUrl,
            bannerBlurhash: userDetails.bannerBlurhash,
            description: userDetails.description ?? "",
            fields: fields,
            location: userDetails.location,
            birthday: userDetails.birthday,
            followersCount: userDetails.followersCount ?? 0,
            followingCount: userDetails.followingCount ?? 0,
            notesCount: userDetails.notesCount ?? 0,
            pinnedNoteIds: userDetails.pinnedNoteIds ?? [],
            publiclyVisible: userDetails.ffVisibility == "public",
            isLocked: userDetails.isLocked ?? false,
            isFollowing: userDetails.isFollowing ?? false,
            isFollowed: userDetails.isFollowed ?? false,
            hasPendingFollowRequestFromYou: userDetails.hasPendingFollowRequestFromYou ?? false,
            hasPendingFollowRequestToYou: userDetails.hasPendingFollowRequestToYou ?? false,
            isBlocking: userDetails.isBlocking ?? false,
            isBlocked: userDetails.isBlocked ?? false,
            isMuted: userDetails.isMuted ?? false,
            mutedWords: userDetails.mutedWords?.flatMap { $0 } ?? []
        )
    }
}
