//
//  Module+FollowRecord.swift
//
//
//  Created by Lakr Aream on 2023/1/18.
//

import BetterCodable
import Foundation

public struct NMFollowRecord: Codable {
    public var id: String
    public var createdAt: String
    @LossyOptional public var followee: NMUserDetails?
    @LossyOptional public var follower: NMUserDetails?
    @LossyOptional public var followeeId: String?
    @LossyOptional public var followerId: String?
}
