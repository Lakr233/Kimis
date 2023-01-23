//
//  NotificationCell+Unsupported.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

extension NotificationCell {
    class UnsupportedCell: NotificationCell {
        let title = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            container.addSubview(title)
            title.textAlignment = .center
            title.font = .systemFont(ofSize: 12)
            title.textColor = .gray
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let bounds = container.bounds
            title.frame = bounds
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            title.text = "Unsupported Notification"
        }

        override func load(_ context: NotificationCell.Context) {
            super.load(context)
            title.text = "Unsupported Notification \(context.notification?.type.rawValue ?? "(undefined)")"
        }
    }
}
