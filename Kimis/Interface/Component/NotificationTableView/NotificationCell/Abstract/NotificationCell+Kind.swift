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
        case .main: NotificationCell.MainCell.self

        case .progress: NotificationCell.ProgressCell.self
        case .separator: NotificationCell.SeparatorCell.self
        case .unsupported: NotificationCell.UnsupportedCell.self
        }
    }

    var designatedHeight: CGFloat? {
        switch self {
        case .separator: 1
        case .progress, .unsupported: 30
        default: nil
        }
    }

    var isSupplymentKind: Bool {
        switch self {
        case .separator: true
        case .progress, .unsupported: true
        default: false
        }
    }
}
