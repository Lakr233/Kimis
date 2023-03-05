//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/28.
//

import Foundation
import Module
import ModuleBridge
import Network
import NetworkModule

public extension Source.NetworkWrapper {
    @discardableResult
    func requestForUserProfile(usingHandler user: String) -> UserProfile? {
        guard let ctx else { return nil }
        let result = ctx.network.requestForUserDetails(userIdOrName: user)
        ctx.spider.spidering(result.extracted)
        if let profile = result.result {
            ctx.spider.spidering(profile)
            return .converting(profile, defaultHost: ctx.receipt.host)
        }
        return nil
    }

    @discardableResult
    func requestForUserFavorites(untilId: String? = nil) -> [NoteID] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForUserFavorite(untilId: untilId)
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result.map(\.id)
    }

    @discardableResult
    func requestForUserNotification(untilId: String? = nil) -> [RemoteNotification] {
        guard let ctx else { return [] }
        let result = ctx.network.requestUserNotifications(untilId: untilId)
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result.compactMap { .converting($0) }
    }

    @discardableResult
    func requestForUsers(limit: Int = 20, offset: Int = 0, origin: Network.UsersOriginType = .combined, state: Network.UsersStateType? = nil, hostname: String? = nil) -> [UserProfile] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForUsers(
            limit: limit,
            offset: offset,
            origin: origin,
            state: state,
            hostname: hostname
        )
        ctx.spider.spidering(result.extracted)
        ctx.spider.spidering(result.result)
        return result.result
            .compactMap { UserProfile.converting($0, defaultHost: ctx.receipt.host) }
    }

    @discardableResult
    func requestForBlockUser(userId: UserID) -> UserProfile? {
        guard let ctx else { return nil }
        let result = ctx.network.requestBlockUser(userId: userId)
        ctx.spider.spidering(result.extracted)
        if let profile = result.result {
            ctx.spider.spidering(profile)
            return .converting(profile, defaultHost: ctx.receipt.host)
        }
        return nil
    }

    @discardableResult
    func requestForUnblockUser(userId: UserID) -> UserProfile? {
        guard let ctx else { return nil }
        let result = ctx.network.requestUnblockUser(userId: userId)
        ctx.spider.spidering(result.extracted)
        if let profile = result.result {
            ctx.spider.spidering(profile)
            return .converting(profile, defaultHost: ctx.receipt.host)
        }
        return nil
    }

    @discardableResult
    func requestForUserFollowers(userId: String, limit: Int = 20, untilId: String? = nil, sinceId: String? = nil) -> [FollowRecord] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForUserFollowers(
            userId: userId,
            limit: limit,
            untilId: untilId,
            sinceId: sinceId
        )
        ctx.spider.spidering(result)
        return result.compactMap {
            .converting($0, defaultHost: ctx.user.host)
        }
    }

    @discardableResult
    func requestForUserFollowing(userId: String, limit: Int = 20, untilId: String? = nil, sinceId: String? = nil) -> [FollowRecord] {
        guard let ctx else { return [] }
        let result = ctx.network.requestForUserFollowing(
            userId: userId,
            limit: limit,
            untilId: untilId,
            sinceId: sinceId
        )
        ctx.spider.spidering(result)
        return result.compactMap {
            .converting($0, defaultHost: ctx.user.host)
        }
    }

    func requestReportUser(userId: String) {
        guard let ctx else { return }
        ctx.network.requestForReportAbuse(userId: userId, comment: "The user was reported by \(ctx.user.absoluteUsername)")
    }
}
