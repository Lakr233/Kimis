//
//  FollowRecord.swift
//
//
//  Created by Lakr Aream on 2023/1/18.
//

import Foundation

public typealias FollowRecordID = String

public class FollowRecord: Codable, Identifiable, Hashable, Equatable {
    public var id: FollowRecordID
    public var createdAt: Date
    public var followee: UserProfile?
    public var follower: UserProfile?
    public var followeeId: String?
    public var followerId: String?

    public init(id: FollowRecordID, createdAt: Date, followee: UserProfile? = nil, follower: UserProfile? = nil, followeeId: String? = nil, followerId: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.followee = followee
        self.follower = follower
        self.followeeId = followeeId
        self.followerId = followerId
    }

    public static func == (lhs: FollowRecord, rhs: FollowRecord) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(createdAt)
        hasher.combine(followee)
        hasher.combine(follower)
        hasher.combine(followeeId)
        hasher.combine(followerId)
    }
}
