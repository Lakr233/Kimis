//
//  Note.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation
import SwiftDate

public typealias NoteID = String

public class Note: Codable, Identifiable, Hashable, Equatable {
    public var id: String { noteId }

    // note id from upstream server
    public var noteId: String
    public var url: URL?

    public var date: Date

    public var contentWarning: String? // Content Warning

    public var text: String
    public var attachments: [Attachment]
    public var reactions: [String: Int]

    public var visibility: String

    /*
     MKVisibility.vue:
     <span v-if="note.visibility !== 'public'" :class="$style.visibility">
         <i v-if="note.visibility === 'home'" class="fas fa-home"></i>
         <i v-else-if="note.visibility === 'followers'" class="fas fa-unlock"></i>
         <i v-else-if="note.visibility === 'specified'" ref="specified" class="fas fa-envelope"></i>
     </span>
     */

    // user
    public var userId: String
    public var userInstance: Instance?
    public var userReaction: String

    public var renoteId: String?
    public var replyId: String?
    public var tags: [String]
    public var mentions: [String]
    public var poll: Poll?

    public struct Poll: Codable, Identifiable, Hashable, Equatable {
        public var id: Int { hashValue }

        public var multiple: Bool
        public var expiresAt: Date?
        public var choices: [Choice]

        public var isInteractive: Bool {
            if multiple {
                let votedCount = choices.map(\.isVoted).count(where: { $0 })
                if votedCount == choices.count { return false }
            } else {
                for choice in choices where choice.isVoted {
                    return false
                }
            }
            if let expire = expiresAt, expire.timeIntervalSinceNow < 0 {
                return false
            }
            return true
        }

        public var totalVotes: Int {
            choices.map(\.votes).reduce(0, +)
        }

        public init(multiple: Bool, expiresAt: Date?, choices: [Note.Poll.Choice]) {
            self.multiple = multiple
            self.expiresAt = expiresAt
            self.choices = choices
        }

        public struct Choice: Codable, Identifiable, Hashable, Equatable {
            public var id: Int { hashValue }

            public var text: String
            public var votes: Int
            public var isVoted: Bool
            public var percent: Double

            public init(text: String, votes: Int, isVoted: Bool, percent: Double) {
                self.text = text
                self.votes = votes
                self.isVoted = isVoted
                var percent = percent
                if percent < 0 { percent = 0 }
                if percent > 1 { percent = 1 }
                self.percent = percent
            }

            public static func == (lhs: Choice, rhs: Choice) -> Bool {
                lhs.hashValue == rhs.hashValue
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(text)
                hasher.combine(votes)
                hasher.combine(isVoted)
            }
        }

        public static func == (lhs: Poll, rhs: Poll) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(multiple)
            hasher.combine(expiresAt)
            hasher.combine(choices)
        }
    }

    public init(noteId: String, url: URL? = nil, date: Date = Date(timeIntervalSince1970: 0), contentWarning: String? = nil, text: String = "", attachments: [Attachment] = [], reactions: [String: Int] = [:], visibility: String = "", userId: String = "", userInstance: Instance? = nil, userReaction: String = "", renoteId: String? = nil, replyId: String? = nil, tags: [String] = [], mentions: [String] = [], poll: Poll? = nil) {
        self.noteId = noteId
        self.url = url
        self.date = date
        self.contentWarning = contentWarning
        self.text = text
        self.attachments = attachments
        self.reactions = reactions
        self.visibility = visibility
        self.userId = userId
        self.userInstance = userInstance
        self.userReaction = userReaction
        self.renoteId = renoteId
        self.replyId = replyId
        self.tags = tags
        self.mentions = mentions
        self.poll = poll
    }

    public static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(noteId)
        hasher.combine(url)
        hasher.combine(date)
        hasher.combine(contentWarning)
        hasher.combine(text)
        hasher.combine(attachments)
        hasher.combine(reactions)
        hasher.combine(visibility)
        hasher.combine(userId)
        hasher.combine(userInstance)
        hasher.combine(userReaction)
        hasher.combine(renoteId)
        hasher.combine(replyId)
        hasher.combine(tags)
        hasher.combine(mentions)
        hasher.combine(poll)
    }
}

public extension Note {
    var justRenote: Bool {
        if renoteId != nil,
           text.isEmpty,
           contentWarning?.isEmpty ?? true,
           attachments.isEmpty,
           poll?.choices.isEmpty ?? true
        {
            return true
        }
        return false
    }
}
