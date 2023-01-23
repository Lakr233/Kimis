//
//  HashtagNoteController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import Combine
import Source
import UIKit

class HashtagNoteController: ViewController, RouterDatable {
    var associatedData: Any? {
        didSet { assert(oldValue == nil) }
    }

    var hashtag: String? {
        guard var tag = associatedData as? String else {
            return nil
        }
        if tag.hasPrefix("#") { tag.removeFirst() }
        return tag
    }

    let refreshControl = UIRefreshControl()
    var hashtagTableView: HashtagTableView? {
        didSet {
            assert(oldValue == nil)
            guard let tableView = hashtagTableView else {
                assertionFailure()
                return
            }
            tableView.clipsToBounds = false
            view.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "#️⃣"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let hashtag, !hashtag.isEmpty else {
            assertionFailure()
            dismiss(animated: true)
            return
        }
        title = "#️⃣ \(hashtag)"

        let tableView = HashtagTableView(hashtag: hashtag)
        hashtagTableView = tableView

        tableView.contentInset = .init(top: -1, left: 0, bottom: 0, right: 0)
        tableView.refreshControl = refreshControl
        tableView.updateFetchRequest.send(true) // directionNewer: true
        refreshControl.addTarget(self, action: #selector(refreshControlValueChange), for: .valueChanged)

        tableView.$scrollLocation
            .throttle(for: .seconds(0.1), scheduler: DispatchQueue.global(), latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.didScroll(toPosition: value.y)
            }
            .store(in: &tableView.cancellable)
    }

    @objc func refreshControlValueChange() {
        withMainActor(delay: 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.hashtagTableView?.updateFetchRequest.send(true)
        }
    }

    func didScroll(toPosition offset: CGFloat) {
        guard let tableView = hashtagTableView else { return }
        // check bottom
        // actual offset tableView.contentSize.height - tableView.frame.height - 10 + tableView.contentInset.vertical
        // but we are going to ignore the inset anyway
        if tableView.contentSize.height > tableView.frame.height {
            // make sure to have content before calling it too much time
            if offset > tableView.contentSize.height - tableView.frame.height - 10, !tableView.isFetching {
                tableView.updateFetchRequest.send(false)
            }
        } // otherwise refresh control is used
    }
}
