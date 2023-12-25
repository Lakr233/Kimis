//
//  NotificationSource+Fetcher.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation

public extension NotificationSource {
    enum FetchDirection: String {
        case new
        case more
    }

    func fetchNotification(direction: FetchDirection, completion: (() -> Void)? = nil) {
        guard ticket == nil, throttle.timeIntervalSinceNow < 0 else { return }
        let ticket = UUID()
        self.ticket = ticket
        DispatchQueue.global().async {
            defer { completion?() }

            var throttleNext: TimeInterval = 2
            defer {
                self.ticket = nil
                self.throttle = Date() + throttleNext
            }
            var untilId: NoteID?
            var copy = self.dataSource
            switch direction {
            case .new: break
            case .more: untilId = copy.last?.notificationId
            }
            let result = self.ctx?.req.requestForUserNotification(untilId: untilId) ?? []
            if result.isEmpty {
                throttleNext = 5
                return
            }

            switch direction {
            case .new:
                var shouldInherit = false
                if let clipA = result.last?.createdAt,
                   let clipB = copy.first?.createdAt,
                   clipA >= clipB
                {
                    shouldInherit = true
                } else if result.last == copy.first {
                    shouldInherit = true
                }
                if shouldInherit {
                    copy = result + copy
                } else {
                    copy = result
                }
            case .more: copy.append(contentsOf: result)
            }
            copy.sort { $0.createdAt > $1.createdAt }

            var final = [RemoteNotification]()
            var deduplicate: Set<RemoteNotificationID> = []
            for notification in copy where !deduplicate.contains(notification.notificationId) {
                final.append(notification)
                deduplicate.insert(notification.notificationId)
            }
            print("[*] \(result.count) notifications fetched, total \(final.count), barrier \(final.last?.createdAt.toString() ?? "nil")")
            self.dataSource = final
        }
    }
}
