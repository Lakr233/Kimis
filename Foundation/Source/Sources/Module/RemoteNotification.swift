//
//  RemoteNotification.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation

public typealias RemoteNotificationID = RemoteNotification.ID

public class RemoteNotification: Codable, Identifiable, Hashable, Equatable {
    public var id: String {
        notificationId
    }

    public let notificationId: String
    public let createdAt: Date
    public let isRead: Bool
    public let type: Kind
    public let userId: String?
    public let noteId: String?
    public let reaction: String?

    public init(notificationId: String, createdAt: Date, isRead: Bool, type: RemoteNotification.Kind, userId: String? = nil, noteId: String? = nil, reaction: String? = nil) {
        self.notificationId = notificationId
        self.createdAt = createdAt
        self.isRead = isRead
        self.type = type
        self.userId = userId
        self.noteId = noteId
        self.reaction = reaction
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationId)
        hasher.combine(createdAt)
        hasher.combine(isRead)
        hasher.combine(type)
        hasher.combine(userId)
        hasher.combine(noteId)
        hasher.combine(reaction)
    }

    public static func == (lhs: RemoteNotification, rhs: RemoteNotification) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public extension RemoteNotification {
    enum Kind: String, Codable {
        case follow
        case mention
        case reply
        case renote
        case quote
        case reaction
        case pollVote
        case pollEnded
        case receiveFollowRequest
        case followRequestAccepted
        case groupInvited
        case app

        case unknown
    }
}
