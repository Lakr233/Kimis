//
//  NotificationTableView+Footer.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import UIKit

extension NotificationTableView {
    func prepareFooter() {
        tableFooterView = progressIndicator
        tableFooterView?.frame.size.height = progressIndicator.intrinsicContentSize.height
    }
}
