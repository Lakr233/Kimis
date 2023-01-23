//
//  UITableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/5.
//

import UIKit

extension UITableView {
    func isExist(indexPath: IndexPath) -> Bool {
        if indexPath.section >= numberOfSections {
            return false
        }
        if indexPath.row >= numberOfRows(inSection: indexPath.section) {
            return false
        }
        return true
    }
}
