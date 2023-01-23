//
//  File.swift
//
//
//  Created by Lakr Aream on 2023/1/2.
//

import Foundation

public struct NMPost: Codable {
    public var text: String?
    public var fileIds: [String]?
    public var poll: Poll? = nil
    public var cw: String?
    public var localOnly: Bool = false
    public var visibility: String = "public"
    public var visibleUserIds: [String]? = nil

    public struct Poll: Codable {
        public var expiresAt: Int? // in ms, Date().timeIntervalSince1970 * 1000
        public var choices: [String]
        public var multiple: Bool

        public init(expiresAt: Int?, choices: [String], multiple: Bool) {
            self.expiresAt = expiresAt
            self.choices = choices
            self.multiple = multiple
        }
    }

    public init(
        text: String? = nil,
        fileIds: [String]? = nil,
        poll: NMPost.Poll? = nil,
        cw: String? = nil,
        localOnly: Bool = false,
        visibility: String = "public",
        visibleUserIds: [String]? = nil
    ) {
        self.text = text
        self.fileIds = fileIds
        self.poll = poll
        self.cw = cw
        self.localOnly = localOnly
        self.visibility = visibility
        self.visibleUserIds = visibleUserIds
    }
}
