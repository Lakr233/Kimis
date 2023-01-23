//
//  NotificationCell+Context.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import UIKit

extension NotificationCell {
    class Context: Identifiable, Equatable, Hashable {
        var id: Int { hashValue }

        let kind: CellKind
        var cellHeight: CGFloat = 0 // TODO: 0
        let notification: RemoteNotification?
        var snapshot: (any AnySnapshot)?
        var read: Bool = false

        init(kind: CellKind, notification: RemoteNotification? = nil) {
            self.kind = kind
            self.notification = notification

            if let height = kind.designatedHeight {
                cellHeight = height
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(notification)
        }

        static func == (lhs: NotificationCell.Context, rhs: NotificationCell.Context) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
