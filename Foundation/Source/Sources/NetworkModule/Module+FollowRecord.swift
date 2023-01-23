//
//  File.swift
//
//
//  Created by Lakr Aream on 2023/1/18.
//

import Foundation

public struct NMFollowRecord: Codable {
    public var id: String
    public var createdAt: String
    public var followee: NMUserDetails?
    public var follower: NMUserDetails?
    public var followeeId: String?
    public var followerId: String?
}
