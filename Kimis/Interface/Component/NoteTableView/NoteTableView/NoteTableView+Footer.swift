//
//  NoteTableView+Footer.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/22.
//

import UIKit

extension NoteTableView {
    func prepareFooter() {
        tableFooterView = progressIndicator
        tableFooterView?.frame.size.height = progressIndicator.intrinsicContentSize.height
    }
}
