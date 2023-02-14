//
//  HashtagTrendController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import Combine
import Source
import UIKit

class HashtagTrendController: ViewController {
    let tableView = TrendingTableView()
    let refreshControl = UIRefreshControl()

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Trending"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshControlValue), for: .valueChanged)

        source?.trending.populateTrending()
    }

    @objc func refreshControlValue() {
        withMainActor(delay: 1.0) {
            self.refreshControl.endRefreshing()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.source?.trending.populateTrending()
            presentMessage("Trending Hashtag Updated")
        }
    }
}

extension HashtagTrendController: LLNavControllerAttachable {
    func createRightBarView() -> UIView? {
        @DefaultButton(icon: .fluent(.search_filled))
        var button: UIButton
        button.imageView?.tintColor = .accent
        button.snp.makeConstraints { make in
            make.width.equalTo(30)
        }
        button.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        return button
    }

    func determineRightBarWidth() -> CGFloat? {
        30
    }

    @objc func openSearch() {
        ControllerRouting.pushing(tag: .search, referencer: self, associatedData: nil)
    }
}
