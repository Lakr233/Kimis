//
//  SmallUsersListController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import UIKit

class SmallUsersListController: UsersListController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: refreshBarItem)
    }
}
