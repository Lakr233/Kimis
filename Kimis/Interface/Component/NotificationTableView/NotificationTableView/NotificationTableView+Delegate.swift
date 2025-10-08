//
//  NotificationTableView+Delegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import UIKit

extension NotificationTableView: UITableViewDelegate, UITableViewDataSource {
    func retainContext(atIndexPath indexPath: IndexPath) -> NotificationCell.Context? {
        assert(Thread.isMainThread)
        return notifications[safe: indexPath.row]
    }

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        notifications.count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = retainContext(atIndexPath: indexPath) else {
            assertionFailure()
            return .init()
        }
        guard let cell = dequeueReusableCell(withIdentifier: data.kind.cellId, for: indexPath) as? NotificationCell else {
            assertionFailure()
            return .init()
        }
        cell.load(data)
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let data = retainContext(atIndexPath: indexPath) else {
            assertionFailure()
            return 0
        }
        return data.cellHeight
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        withMainActor(delay: 0.1) {
            self.deselectRow(at: indexPath, animated: true)
        }
        guard let data = retainContext(atIndexPath: indexPath),
              let notification = data.notification
        else {
            return
        }
        didSelect(notification)
    }

    var itemCount: Int {
        notifications
            .map(\.kind)
            .count(where: { value in
                switch value {
                case .main: true
//                case .note: return true
//                case .reaction: return true
//                case .follow: return true
//                case .followRequest: return true
//                case .followAccepted: return true
//                case .vote: return true
                default: false
                }
            })
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        guard let footer = dequeueReusableHeaderFooterView(
            withIdentifier: FooterCountView.identifier
        ) as? FooterCountView else {
            return nil
        }
        let count = itemCount
        if count > 0 {
            footer.set(title: L10n.text("%d notification(s)", count))
        } else {
            footer.set(title: L10n.text("🥲 Nothing Here"))
        }
        return footer
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        FooterCountView.footerHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        self.tableView(tableView, heightForFooterInSection: section)
    }
}
