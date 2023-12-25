//
//  NoteCell+Kind.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/22.
//

import UIKit

extension NoteCell {
    enum CellKind: String, CaseIterable, Codable {
        case abstract
        case separator
        case progress
        case moreHeader
        case main
        case pinned
        case reply
        case full
        case moreReply
        case moreReplyPadded
        case replyPadded

        var cellId: String { rawValue }
        var cell: NoteCell.Type {
            switch self {
            case .abstract: NoteCell.self
            case .separator: NoteCell.Separator.self
            case .progress: NoteCell.Progress.self
            case .moreHeader: MoreHeaderCell.self
            case .main: MainCell.self
            case .pinned: PinnedCell.self
            case .reply: ReplyCell.self
            case .full: FullCell.self
            case .moreReply: MoreReplyHeaderCell.self
            case .moreReplyPadded: MoreReplyPaddedCell.self
            case .replyPadded: ReplyPaddedCell.self
            }
        }

        var designatedHeight: CGFloat? {
            switch self {
            case .separator: 1
            case .moreHeader, .moreReplyPadded, .moreReply, .progress: 30
            default: nil
            }
        }

        var isSupplymentKind: Bool {
            switch self {
            case .abstract: true
            case .separator: true
            case .progress: true
            case .moreHeader: true
            case .moreReply: true
            default: false
            }
        }
    }

    static func registeringCells(for tableView: UITableView) {
        for cell in CellKind.allCases {
            tableView.register(cell.cell, forCellReuseIdentifier: cell.cellId)
        }
    }
}
