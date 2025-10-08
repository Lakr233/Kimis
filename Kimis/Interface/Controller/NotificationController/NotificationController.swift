//
//  NotificationController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

class NotificationController: ViewController {
    let updateMoreRequestSubject = CurrentValueSubject<Bool, Never>(true)

    let tableView = NotificationTableView()
    let refreshControl = UIRefreshControl()

    init() {
        super.init(nibName: nil, bundle: nil)
        title = L10n.text("Notification")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        view.clipsToBounds = false
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)

        tableView.$scrollLocation
            .throttle(for: .seconds(0.1), scheduler: DispatchQueue.global(), latest: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.didScroll(toPosition: value.y)
            }
            .store(in: &tableView.cancellable)

        updateMoreRequestSubject
            .throttle(for: .seconds(2), scheduler: DispatchQueue.global(), latest: false)
            .sink { [weak self] _ in
                self?.source?.notifications.fetchNotification(direction: .more)
            }
            .store(in: &tableView.cancellable)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        source?.notifications.markPosted()
    }

    @objc func refreshControlValueChanged() {
        withMainActor(delay: 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.source?.notifications.fetchNotification(direction: .new)
        }
    }

    func didScroll(toPosition offset: CGFloat) {
        if offset > tableView.contentSize.height - tableView.frame.height - 10, !(source?.notifications.updating ?? true) {
            updateMoreRequestSubject.send(true)
        }
    }
}

extension NotificationController {
    @objc func markNewestAsRead() {
        source?.notifications.readAll()
        presentMessage(L10n.text("Marked All Read"))
    }
}
