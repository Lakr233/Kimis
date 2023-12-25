//
//  RemoteNotification.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation
import Module
import NetworkModule
import SwiftDate

public extension RemoteNotification {
    static func converting(_ notification: NMNotification) -> RemoteNotification? {
        guard let date = notification.createdAt.toISODate(nil, region: nil)?.date else {
            return nil
        }
        guard let type = Kind(rawValue: notification.type.rawValue) else {
            return nil
        }
        return RemoteNotification(
            notificationId: notification.id,
            createdAt: date,
            isRead: notification.isRead ?? false,
            type: type,
            userId: notification.userId,
            noteId: notification.note?.id,
            reaction: notification.reaction
        )
    }
}
