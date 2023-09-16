//
//  NotificationTableView+Reload.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

extension NotificationTableView {
    func requestReload(toTarget target: [NotificationCell.Context], ticket: UUID) {
        assert(Thread.isMainThread)
        guard ticket == renderTicket else { return }
        defer {
            renderTicket = .init()
        }

        notifications = target
        reloadData()
    }
}
