//
//  RemoteNotification.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/15.
//

import UIKit

extension RemoteNotification.Kind {
    var tintIcon: UIImage? {
        switch self {
        case .follow: UIImage(systemName: "person.crop.circle.badge.plus")
        case .mention: UIImage(systemName: "at")
        case .reply: UIImage(systemName: "arrowshape.turn.up.left.circle.fill")
        case .renote: UIImage(systemName: "arrowshape.turn.up.right.circle.fill")
        case .quote: UIImage(systemName: "quote.bubble")
        case .reaction: nil
        case .pollVote: UIImage(systemName: "checkmark.circle.fill")
        case .pollEnded: UIImage(systemName: "timeline.selection")
        case .receiveFollowRequest: UIImage(systemName: "person.crop.square")
        case .followRequestAccepted: UIImage(systemName: "person.crop.circle.badge.checkmark")
        case .groupInvited: UIImage(systemName: "person.fill.badge.plus")
        case .app: UIImage(systemName: "app.badge.fill")

        default: UIImage(systemName: "questionmark.circle")
        }
    }

    var title: String {
        switch self {
        case .follow: "Followed you"
        case .mention: "Mentioned you"
        case .reply: "Replied to you"
        case .renote: "Forward your note"
        case .quote: "Quote"
        case .reaction: "Reacted with you"
        case .pollVote: "Voted a poll"
        case .pollEnded: "Poll ended"
        case .receiveFollowRequest: "You have a follow request"
        case .followRequestAccepted: "Your follow request was accepted"
        case .groupInvited: "You are invited"
        case .app: "Application Message"

        default: "Unknown Message"
        }
    }
}
