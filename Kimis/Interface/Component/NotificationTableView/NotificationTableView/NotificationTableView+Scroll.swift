//
//  NotificationTableView+Scroll.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import UIKit

extension NotificationTableView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollLocation = scrollView.contentOffset
    }
}
