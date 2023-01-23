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
            case .abstract: return NoteCell.self
            case .separator: return NoteCell.Separator.self
            case .progress: return NoteCell.Progress.self
            case .moreHeader: return MoreHeaderCell.self
            case .main: return MainCell.self
            case .pinned: return PinnedCell.self
            case .reply: return ReplyCell.self
            case .full: return FullCell.self
            case .moreReply: return MoreReplyHeaderCell.self
            case .moreReplyPadded: return MoreReplyPaddedCell.self
            case .replyPadded: return ReplyPaddedCell.self
            }
        }

        var designatedHeight: CGFloat? {
            switch self {
            case .separator: return 1
            case .moreHeader, .moreReplyPadded, .moreReply, .progress: return 30
            default: return nil
            }
        }

        var isSupplymentKind: Bool {
            switch self {
            case .abstract: return true
            case .separator: return true
            case .progress: return true
            case .moreHeader: return true
            case .moreReply: return true
            default: return false
            }
        }
    }

    static func registeringCells(for tableView: UITableView) {
        for cell in CellKind.allCases {
            tableView.register(cell.cell, forCellReuseIdentifier: cell.cellId)
        }
    }
}
