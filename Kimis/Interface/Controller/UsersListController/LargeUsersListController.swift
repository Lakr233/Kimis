//
//  LargeUsersListController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import UIKit

class LargeUsersListController: UsersListController, LLNavControllerAttachable {
    func createRightBarView() -> UIView? {
        refreshBarItem
    }

    func determineRightBarWidth() -> CGFloat? {
        30
    }
}
