//
//  Context+Builder.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation
import Module

extension NotificationCell.Context {
    convenience init?(representing notification: RemoteNotification) {
//        var kind: NotificationCell.CellKind?
//        switch notification.type {
//        case .mention: kind = .main
//        case .reply: kind = .main
//        case .renote: kind = .main
//        case .quote: kind = .main
//        case .follow: kind = .main
//        case .reaction: kind = .main
//        case .receiveFollowRequest: kind = .main
//        case .followRequestAccepted: kind = .main
//
//        case .app: kind = .main
//
//        case .pollVote: kind = .main
//        case .pollEnded: kind = .main
//
//        case .groupInvited: kind = .main
//        }
//
//        guard let kind else { return nil }

        let kind = NotificationCell.CellKind.main

        self.init(kind: kind, notification: notification)
    }
}
