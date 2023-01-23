//
//  PostEditorPollView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/13.
//

import Combine
import Source
import UIKit

class PostEditorPollView: UIView {
    let post: Post
    let spacing: CGFloat
    let tableView = UITableView()

    enum Section { case main }
    struct Binder: Hashable {
        let post: Post
        let index: Int?
        let spacing: CGFloat

        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
        }
    }

    typealias DataSource = UITableViewDiffableDataSource<Section, Binder>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Binder>
    var dataSource: DataSource?

    var contentSize: CGSize {
        if post.poll == nil {
            return .zero
        }
        return tableView.contentSize
    }

    init(post: Post, spacing: CGFloat) {
        self.post = post
        self.spacing = spacing

        tableView.clipsToBounds = false
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(PollEditorCell.self, forCellReuseIdentifier: PollEditorCell.cellId)
        tableView.register(PollEditorControlCell.self, forCellReuseIdentifier: PollEditorControlCell.cellId)

        super.init(frame: .zero)

        addSubview(tableView)

        dataSource = makeDataSource()
        applySnapshot()
        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }

    func reloadAndPrepareForNewFrame() {
        applySnapshot()
        for cell in tableView.visibleCells {
            if let cell = cell as? PollEditorCell {
                cell.syncValue()
            }
        }
        tableView.beginUpdates()
        tableView.endUpdates()
        layoutIfNeeded()
    }
}
