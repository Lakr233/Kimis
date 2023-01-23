//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/15.
//

import Foundation

public struct LoginChallengeReceipt: Identifiable, Codable, Equatable, Hashable {
    public var id: String { universalIdentifier }

    // these value is not planing for any change
    // so store it and make then read only
    public let accountId: String
    public let username: String
    public let host: String
    public let token: String
    public let challenge: String // we keep a reference

    // this is used to calculate database path and user defaults suite name
    public var universalIdentifier: String {
        "@\(username)@\(host)".lowercased()
    }

    internal init(accountId: String, username: String, host: String, token: String, challenge: String) {
        self.accountId = accountId
        self.username = username
        self.host = host
        self.token = token
        self.challenge = challenge
    }
}
