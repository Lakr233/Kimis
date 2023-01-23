//
//  User.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/3.
//

import Foundation
import Module

extension User {
    static let unavailableUserId = "__missing_user__"

    static let unavailable: User = .init(
        userId: unavailableUserId,
        name: "Unknown",
        username: "Unknown",
        host: "localhost",
        avatarUrl: nil,
        avatarBlurHash: nil,
        isAdmin: false,
        isBot: false,
        isModerator: false,
        isCat: false
    )
}
