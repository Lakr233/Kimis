//
//  NotificationTableView+Render.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import UIKit

extension NotificationTableView {
    func requestRenderUpdate(target: [RemoteNotification], readAllBefore: Date = Date(timeIntervalSince1970: 0), width: CGFloat, ticket: UUID) {
        let build = Self.translate(notifications: target, readAllBefore: readAllBefore)
        build.forEach { $0.renderLayout(usingWidth: width, source: source) }
        withMainActor {
            self.requestReload(toTarget: build, ticket: ticket)
        }
    }

    static func translate(notifications target: [RemoteNotification], readAllBefore: Date = Date(timeIntervalSince1970: 0)) -> [NotificationCell.Context] {
        var build: [NotificationCell.Context] = [
            .init(kind: .separator),
        ]
        for item in target {
            guard let context = NotificationCell.Context(representing: item) else {
                assertionFailure()
                continue
            }
            if item.createdAt <= readAllBefore { context.read = true }
            build.append(context)
            build.append(.init(kind: .separator))
        }
        return build
    }
}
