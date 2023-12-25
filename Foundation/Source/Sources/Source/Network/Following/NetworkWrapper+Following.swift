//
//  NetworkWrapper+Following.swift
//
//
//  Created by Lakr Aream on 2022/11/29.
//

import Foundation

public extension Source.NetworkWrapper {
    func requestFollow(userId: String) {
        guard let ctx else { return }
        ctx.network.requestFollowingCreate(to: userId)
    }

    func requestFollowDelete(userId: String) {
        guard let ctx else { return }
        ctx.network.requestFollowingDelete(to: userId)
    }

    func requestFollowCancel(userId: String) {
        guard let ctx else { return }
        ctx.network.requestFollowingRequestCancel(to: userId)
    }

    func requestFollowerApprove(userId: String) {
        guard let ctx else { return }
        ctx.network.requestFollowingRequestAccept(to: userId)
    }

    func requestFollowerReject(userId: String) {
        guard let ctx else { return }
        ctx.network.requestFollowingRequestReject(to: userId)
    }

    func requestFollowerInvalidate(userId: String) {
        guard let ctx else { return }
        ctx.network.requestFollowingInvalidate(to: userId)
    }
}
