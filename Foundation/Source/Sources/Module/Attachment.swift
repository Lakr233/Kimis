//
//  Attachment.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation

public typealias AttachmentID = String

public class Attachment: Codable, Identifiable, Hashable, Equatable {
    public var id: String { attachId }

    public var attachId: String // from upstream server
    public var name: String
    public var user: String // user ID not UUID

    // networking
    public var url: URL
    public var contentType: String
    public var contentSize: Int

    // hint
    public var previewBlurHash: String?
    public var preferredWidth: Int?
    public var preferredHeight: Int?
    public var isSensitive: Bool

    public init(attachId: String, name: String, user: String, url: URL, contentType: String, contentSize: Int, previewBlurHash: String?, preferredWidth: Int?, preferredHeight: Int?, isSensitive: Bool) {
        self.attachId = attachId
        self.name = name
        self.user = user
        self.url = url
        self.contentType = contentType
        self.contentSize = contentSize
        self.previewBlurHash = previewBlurHash
        self.preferredWidth = preferredWidth
        self.preferredHeight = preferredHeight
        self.isSensitive = isSensitive
    }

    public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        true &&
            lhs.id == rhs.id &&
            lhs.attachId == rhs.attachId &&
            lhs.name == rhs.name &&
            lhs.user == rhs.user &&
            lhs.url == rhs.url &&
            lhs.contentType == rhs.contentType &&
            lhs.contentSize == rhs.contentSize &&
            lhs.previewBlurHash == rhs.previewBlurHash &&
            lhs.preferredWidth == rhs.preferredWidth &&
            lhs.preferredHeight == rhs.preferredHeight &&
            lhs.isSensitive == rhs.isSensitive
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(attachId)
        hasher.combine(name)
        hasher.combine(user)
        hasher.combine(url)
        hasher.combine(contentType)
        hasher.combine(contentSize)
        hasher.combine(previewBlurHash)
        hasher.combine(preferredWidth)
        hasher.combine(preferredHeight)
        hasher.combine(isSensitive)
    }
}
