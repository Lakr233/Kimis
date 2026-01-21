//
//  FollowRecord.swift
//
//
//  Created by Lakr Aream on 2023/1/18.
//

import Foundation
import Module
import NetworkModule
import SwiftDate

public extension FollowRecord {
    static func converting(_ record: NMFollowRecord, defaultHost: String) -> FollowRecord? {
        let followee = UserProfile.converting(record.followee, defaultHost: defaultHost)
        let follower = UserProfile.converting(record.follower, defaultHost: defaultHost)
        guard let date = record.createdAt.toISODate(nil, region: nil)?.date else {
            return nil
        }
        return .init(
            id: record.id,
            createdAt: date,
            followee: followee,
            follower: follower,
            followeeId: record.followeeId,
            followerId: record.followerId,
        )
    }
}
