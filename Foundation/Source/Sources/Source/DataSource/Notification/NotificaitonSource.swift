//
//  NotificationSource.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation
import Network

private let kMaxNotificationCount = 1024

public class NotificationSource: ObservableObject {
    weak var ctx: Source?

    @Published public internal(set) var updating: Bool = false
    @Published public internal(set) var dataSource = [RemoteNotification]() {
        didSet {
            if readDate == Date(timeIntervalSince1970: 0) {
                readAll()
            }
            ctx?.properties.setProperty(toKey: .notification, withObject: dataSource)
            recalculateBadgeValueAndUpdate()
        }
    }

    @Published public internal(set) var badgeCount: Int = 0
    @Published public internal(set) var badge: Bool = false

    @Published public internal(set) var readDate = Date(timeIntervalSince1970: 0) {
        didSet {
            ctx?.properties.setProperty(toKey: .notificationRead, withObject: readDate)
            recalculateBadgeValueAndUpdate()
        }
    }

    @Published public internal(set) var notificationPostedDate = Date(timeIntervalSince1970: 0) {
        didSet {
            ctx?.properties.setProperty(toKey: .notificaitonPosted, withObject: notificationPostedDate)
        }
    }

    internal var ticket: UUID? {
        didSet { updating = ticket != nil }
    }

    internal var throttle: Date = .init(timeIntervalSince1970: 0)

    init(context: Source) {
        ctx = context
        dataSource = context.properties.readProperty(
            fromKey: .notification,
            defaultValue: [RemoteNotification]()
        )
        readDate = context.properties.readProperty(
            fromKey: .notificationRead,
            defaultValue: Date(timeIntervalSince1970: 0)
        )
        if dataSource.count > kMaxNotificationCount {
            dataSource.removeLast(dataSource.count - kMaxNotificationCount)
        }
    }

    public func readAll() {
        readDate = max(dataSource.first?.createdAt ?? Date(timeIntervalSince1970: 0), readDate)
        print("[*] NotificationSource marking read date to \(readDate.toString())")
        markPosted()
    }

    // get unposted notifications for system notification center UI
    public func obtainPendingNotificaitonsForPost() -> [RemoteNotification] {
        let notifications = dataSource.filter {
            // is read is a server hint, user may have multiple devices, better to have them posted all
            $0.createdAt > notificationPostedDate && $0.createdAt > readDate
        }
        return notifications
    }

    public func markPosted() {
        notificationPostedDate = max(dataSource.first?.createdAt ?? Date(timeIntervalSince1970: 0), notificationPostedDate)
        print("[*] NotificationSource marking posted to \(readDate.toString())")
    }

    func recalculateBadgeValueAndUpdate() {
        DispatchQueue.global().async {
            let filteredList = self.dataSource.filter {
                $0.createdAt > self.readDate
            }
            self.badgeCount = filteredList.count
            self.badge = !filteredList.isEmpty
        }
    }
}
