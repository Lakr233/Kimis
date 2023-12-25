//
//  Module+Post.swift
//
//
//  Created by Lakr Aream on 2023/1/2.
//

import BetterCodable
import Foundation

public struct NMPost: Codable {
    @LossyOptional public var text: String?
    @LossyOptional public var fileIds: [String]?
    @LossyOptional public var poll: Poll?
    @LossyOptional public var cw: String?
    public var localOnly: Bool = false
    public var visibility: String = "public"
    @LossyOptional public var visibleUserIds: [String]?

    public struct Poll: Codable {
        @LossyOptional public var expiresAt: Int? // in ms, Date().timeIntervalSince1970 * 1000
        public var choices: [String]
        public var multiple: Bool

        public init(expiresAt: Int?, choices: [String], multiple: Bool) {
            self.expiresAt = expiresAt
            self.choices = choices
            self.multiple = multiple
        }
    }

    public init(
        text: String?,
        fileIds: [String]?,
        poll: NMPost.Poll?,
        cw: String?,
        localOnly: Bool = false,
        visibility: String = "public",
        visibleUserIds: [String]?
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
