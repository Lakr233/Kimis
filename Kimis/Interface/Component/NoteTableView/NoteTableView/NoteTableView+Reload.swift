//
//  NoteTableView+Reload.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/22.
//

import Combine
import UIKit

extension NoteTableView {
    func requestReload(toTarget target: [NoteCell.Context]) {
        dataUpdateLock.lock()
        defer { dataUpdateLock.unlock() }
        assert(Thread.isMainThread)
        context = target
        reloadData()
    }
}
