//
//  UsersListController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import Combine
import Source
import UIKit

class UsersListController: ViewController {
    let tableView = UsersListTableView()
    @Published var isLoading: Bool = false

    let refreshBarItem = UIView()

    @DefaultButton(icon: .fluent(.arrow_counterclockwise_filled))
    var refreshButton: UIButton

    let refreshIndicator = UIActivityIndicatorView()

    init() {
        super.init(nibName: nil, bundle: nil)

        title = "Users"

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        refreshBarItem.addSubview(refreshButton)
        refreshBarItem.addSubview(refreshIndicator)
        refreshBarItem.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(30).priority(.low)
        }

        refreshButton.imageView?.tintColor = .accent
        refreshButton.snp.makeConstraints { make in
            make.width.equalTo(30)
        }
        refreshButton.addTarget(self, action: #selector(refreshItems), for: .touchUpInside)
        refreshButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        refreshIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        $isLoading
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    refreshIndicator.startAnimating()
                    refreshIndicator.isHidden = false
                    refreshButton.isHidden = true
                    tableView.progressView.animate()
                } else {
                    refreshButton.isHidden = false
                    refreshIndicator.stopAnimating()
                    refreshIndicator.isHidden = true
                    tableView.progressView.stopAnimate()
                }
            }
            .store(in: &tableView.cancellable)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshItems()
    }

    @objc func refreshItems() {
        guard let source = tableView.source else { return }
        isLoading = true
        DispatchQueue.global().async {
            defer { withMainActor {
                self.isLoading = false
            } }

            let users = source.req.requestForUsers(limit: 50)
                .filter { profile in
                    if source.isTextMuted(text: profile.username) { return false }
                    if source.isTextMuted(text: profile.name) { return false }
                    if source.isTextMuted(text: profile.description) { return false }
                    return true
                }
            withMainActor { self.tableView.users = users }
        }
    }
}
