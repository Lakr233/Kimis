//
//  Post.swift
//
//
//  Created by Lakr Aream on 2023/1/2.
//

import Foundation
import Module
import NetworkModule

public extension NMPost.Poll {
    static func converting(_ poll: Post.Poll) -> NMPost.Poll {
        var expire: Int?
        if let exp = poll.expiresAt?.timeIntervalSince1970 {
            expire = Int(exp) * 1000
        }
        return .init(expiresAt: expire, choices: poll.choices, multiple: poll.multiple)
    }
}

public extension NMPost {
    static func converting(_ post: Post) -> NMPost? {
        var poll: NMPost.Poll?
        if let p = post.poll { poll = .converting(p) }
        var fileIds: [String]?
        if post.attachments.count > 0 {
            fileIds = post.attachments.map(\.attachId)
        }
        var cw: String?
        if post.cw?.count ?? 0 > 0 {
            cw = post.cw
        }
        var users: [String]?
        if post.visibleUserIds.count > 0 {
            users = post.visibleUserIds
        }
        return .init(
            text: post.text,
            fileIds: fileIds,
            poll: poll,
            cw: cw,
            localOnly: post.localOnly,
            visibility: post.visibility.rawValue,
            visibleUserIds: users,
        )
    }
}
