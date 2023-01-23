//
//  PostEditorPollView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/13.
//

import Combine
import Source
import UIKit

extension PostEditorPollView: UITableViewDelegate {
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, binder ->
                UITableViewCell? in
                if let idx = binder.index {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: PollEditorCell.cellId,
                        for: indexPath
                    ) as! PollEditorCell
                    cell.bind(post: binder.post, index: idx)
                    cell.spacing = binder.spacing
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: PollEditorControlCell.cellId,
                        for: indexPath
                    ) as! PollEditorControlCell
                    cell.bind(post: binder.post)
                    cell.spacing = binder.spacing
                    return cell
                }
            }
        )
        return dataSource
    }

    func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        var builder = [Binder]()
        for idx in 0 ..< (post.poll?.choices.count ?? 0) {
            builder.append(.init(post: post, index: idx, spacing: spacing))
        }
        builder.append(.init(post: post, index: nil, spacing: spacing)) // control
        snapshot.appendItems(builder)
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}
