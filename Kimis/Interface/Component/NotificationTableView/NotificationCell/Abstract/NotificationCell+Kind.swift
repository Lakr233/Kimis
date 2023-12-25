//
//  NotificationCell+Kind.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

extension NotificationCell {
    enum CellKind: String, CaseIterable {
        case main

//        case note
//        case reaction
//        case follow
//        case followRequest
//        case followAccepted
//        case vote

        case separator
        case progress
        case unsupported
    }
}

extension NotificationCell {
    static func registeringCells(for tableView: UITableView) {
        for cell in CellKind.allCases {
            tableView.register(cell.cell, forCellReuseIdentifier: cell.cellId)
        }
    }
}

extension NotificationCell.CellKind {
    var cellId: String { rawValue }
    var cell: NotificationCell.Type {
        switch self {
        case .main: return NotificationCell.MainCell.self

        case .progress: return NotificationCell.ProgressCell.self
        case .separator: return NotificationCell.SeparatorCell.self
        case .unsupported: return NotificationCell.UnsupportedCell.self
        }
    }

    var designatedHeight: CGFloat? {
        switch self {
        case .separator: return 1
        case .progress, .unsupported: return 30
        default: return nil
        }
    }

    var isSupplymentKind: Bool {
        switch self {
        case .separator: return true
        case .progress, .unsupported: return true
        default: return false
        }
    }
}
