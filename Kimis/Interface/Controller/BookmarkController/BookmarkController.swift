//
//  BookmarkController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

class BookmarkController: ViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Bookmark"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let tableView = BookmarkTableView()
    let refreshControl = UIRefreshControl()

    var indicators = [UIActivityIndicatorView]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.clipsToBounds = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.contentInset = .init(top: -1, left: 0, bottom: 0, right: 0)

        tableView.$scrollLocation
            .throttle(for: .seconds(0.1), scheduler: DispatchQueue.global(), latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.didScroll(toPosition: value.y)
            }
            .store(in: &tableView.cancellable)

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshControlValueChange), for: .valueChanged)

        source?.bookmark.$updating
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.updateIndicators(value)
            }
            .store(in: &tableView.cancellable)

        let indicator = UIActivityIndicatorView()
        navigationItem.rightBarButtonItem = .init(customView: indicator)
        indicators.append(indicator)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if source?.bookmark.dataSource.isEmpty ?? false {
            source?.bookmark.reloadBookmark()
        }
    }

    @objc func refreshControlValueChange() {
        withMainActor(delay: 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.source?.bookmark.reloadBookmark()
        }
    }

    func didScroll(toPosition offset: CGFloat) {
        if tableView.contentSize.height > tableView.frame.height {
            if offset > tableView.contentSize.height - tableView.frame.height - 10, !(source?.bookmark.updating ?? true) {
                source?.bookmark.fetchMoreBookmark()
            }
        }
    }

    func updateIndicators(_ value: Bool) {
        if value {
            indicators.forEach { $0.startAnimating() }
        } else {
            indicators.forEach { $0.stopAnimating() }
        }
    }
}

extension BookmarkController: LLNavControllerAttachable {
    func createRightBarView() -> UIView? {
        let view = UIView()
        let indicator = UIActivityIndicatorView()
        indicators.append(indicator)
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        return view
    }

    func determineRightBarWidth() -> CGFloat? {
        30
    }
}
