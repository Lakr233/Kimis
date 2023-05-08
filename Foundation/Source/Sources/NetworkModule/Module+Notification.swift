//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import BetterCodable
import Foundation

public struct NMNotification: Codable {
    public let id: String
    public let createdAt: String
    public let isRead: Bool?
    public let type: NotificationType

    public enum NotificationType: String, Codable {
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
        case achievementEarned

        case unknown

        public init(from decoder: Decoder) throws {
            self = try NotificationType(
                rawValue: decoder.singleValueContainer().decode(RawValue.self)
            ) ?? .unknown
        }
    }

    public let user: NMUserLite?
    public let userId: String?

    public let note: NMNote?

    public let reaction: String?
    public let choice: Int?
    public let body: String?
    public let header: String?
    public let icon: String?
}
