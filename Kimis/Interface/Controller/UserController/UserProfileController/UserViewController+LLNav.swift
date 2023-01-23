//
//  UserViewController+LLNav.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import UIKit

extension UserViewController: LLNavControllerAttachable {
    func determineTransparentRequest() -> Bool {
        tableView.contentOffset.y <= 0
    }

    func determineTitleShouldShow() -> Bool {
        tableView.contentOffset.y > 0
    }
}
