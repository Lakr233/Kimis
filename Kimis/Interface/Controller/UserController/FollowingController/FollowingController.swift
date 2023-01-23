//
//  FollowerController.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/18.
//

import Combine
import Source
import UIKit

class FollowingController: ViewController {
    let userId: String

    let tableView = UsersListTableView()
    let refreshControl = UIRefreshControl()

    @Published var isLoading = false
    var progressIndicators = [UIActivityIndicatorView]() {
        didSet { updateIndicator(isLoading) }
    }

    var userList = [FollowRecord]() {
        didSet { tableView.users = userList.compactMap(\.followee) }
    }

    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Following"

        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)

        $isLoading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateIndicator(isLoading)
            }
            .store(in: &tableView.cancellable)

        tableView.$scrollOffset
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.didScroll(to: output)
            }
            .store(in: &tableView.cancellable)

        let indicator = UIActivityIndicatorView()
        progressIndicators.append(indicator)
        navigationItem.rightBarButtonItem = .init(customView: indicator)

        loadMore()
    }

    func updateIndicator(_ isLoading: Bool) {
        if isLoading {
            progressIndicators.forEach { $0.startAnimating() }
        } else {
            progressIndicators.forEach { $0.stopAnimating() }
        }
    }

    @objc func refreshControlValueChanged() {
        withMainActor(delay: 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
        withMainActor(delay: 1.5) { [weak self] in
            self?.userList = []
            self?.loadMore()
        }
    }

    func loadMore() {
        assert(Thread.isMainThread)
        guard !isLoading, let source else { return }
        isLoading = true
        let curr = userList
        let untilId = curr.last?.id
        let userId = userId
        DispatchQueue.global().async {
            defer { withMainActor {
                self.isLoading = false
            } }
            let items = source.req.requestForUserFollowing(
                userId: userId,
                untilId: untilId
            )
            var build = curr + items
            build.removeDuplicates()
            withMainActor { self.userList = build }
        }
    }

    func didScroll(to location: CGPoint) {
        if location.y > tableView.contentSize.height - tableView.frame.height - 10, !isLoading {
            loadMore()
        }
    }
}

extension FollowingController: LLNavControllerAttachable {
    func createRightBarView() -> UIView? {
        let view = UIView()
        let indicator = UIActivityIndicatorView()
        view.addSubview(indicator)
        progressIndicators.append(indicator)
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
