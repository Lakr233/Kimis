//
//  Post.swift
//
//
//  Created by Lakr Aream on 2023/1/2.
//

import Combine
import Foundation

public class Post: Equatable, Hashable {
    public let updated = CurrentValueSubject<Bool, Never>(true)

    public var text: String = "" {
        didSet { if oldValue != text {
            updated.send(true)
        } }
    }

    public var attachments: [Attachment] = [] {
        didSet { if oldValue != attachments {
            updated.send(true)
        } }
    }

    public var poll: Poll? {
        didSet { if oldValue != poll {
            updated.send(true)
        } }
    }

    public var cw: String? {
        didSet { if oldValue != cw {
            updated.send(true)
        } }
    }

    public var localOnly: Bool = false {
        didSet { if oldValue != localOnly {
            updated.send(true)
        } }
    }

    public var visibility: Visibility = .public {
        didSet { if oldValue != visibility {
            updated.send(true)
        } }
    }

    public var visibleUserIds: [UserID] = [] {
        didSet { if oldValue != visibleUserIds {
            updated.send(true)
        } }
    }

    public var selectionHint: NSRange? {
        didSet {
            print("[*] Post editor changed selection to \(String(describing: selectionHint))")
        }
    }

    public var hasContent: Bool {
        if text.count > 0 { return true }
        if !attachments.isEmpty { return true }
        if poll != nil { return true }
        return false
    }

    public struct Poll: Codable, Equatable, Hashable {
        public var expiresAt: Date? // in ms, Date().timeIntervalSince1970 * 1000
        public var choices: [String]
        public var multiple: Bool = false

        public static let maxChoice: Int = 10

        public init(expiresAt: Date? = nil, choices: [String] = ["", ""], multiple: Bool = false) {
            self.expiresAt = expiresAt
            self.choices = choices
            self.multiple = multiple
        }
    }

    public enum Visibility: String, Codable, Equatable, Hashable {
        case `public`
        case home
        case followers
        case specified
    }

    public init(
        text: String = "",
        attachments: [Attachment] = [],
        poll: Poll? = nil,
        cw: String? = nil,
        localOnly: Bool = false,
        visibility: Visibility = .public,
        visibleUserIds: [NoteID] = []
    ) {
        self.text = text
        self.attachments = attachments
        self.poll = poll
        self.cw = cw
        self.localOnly = localOnly
        self.visibility = visibility
        self.visibleUserIds = visibleUserIds

        updated.send(true)
    }

    public static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(attachments)
        hasher.combine(poll)
        hasher.combine(cw)
        hasher.combine(localOnly)
        hasher.combine(visibility)
        hasher.combine(visibleUserIds)
    }
}
