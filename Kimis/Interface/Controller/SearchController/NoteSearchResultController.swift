//
//  NoteSearchResultController.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/21.
//

import Combine
import Source
import UIKit

class NoteSearchResultController: ViewController {
    let tableView = NoteTableView()

    var searchResult = [NoteID]() {
        didSet { sendUpdate() }
    }

    let searchKey: String

    var isLoading: Bool = false {
        didSet { updateIndicators() }
    }

    var indicators: [UIActivityIndicatorView] = [] {
        didSet { updateIndicators() }
    }

    init(searchKey: String) {
        self.searchKey = searchKey
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        title = L10n.text("🔍 %@", searchKey)
        let indicator = UIActivityIndicatorView()
        indicators.append(indicator)
        navigationItem.rightBarButtonItem = .init(customView: indicator)

        tableView.$scrollLocation
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.didScroll(to: output)
            }
            .store(in: &tableView.cancellable)

        loadMore()
    }

    func sendUpdate() {
        let context: [NoteCell.Context] = searchResult.map { [
            NoteCell.Context(kind: .main, noteId: $0),
            NoteCell.Context(kind: .separator),
        ] }
        .flatMap(\.self)
        tableView.updatedSource.send(context)
    }

    func updateIndicators() {
        if isLoading {
            indicators.forEach { $0.startAnimating() }
        } else {
            indicators.forEach { $0.stopAnimating() }
        }
    }

    func didScroll(to location: CGPoint) {
        if location.y > tableView.contentSize.height - tableView.frame.height - 10, !isLoading {
            loadMore()
        }
    }

    func loadMore() {
        assert(Thread.isMainThread)
        guard !isLoading, let source else { return }
        isLoading = true
        let curr = searchResult
        let key = searchKey
        let untilId = searchResult.last
        tableView.footerProgressWorkingJobs += 1
        DispatchQueue.global().async {
            defer { withMainActor {
                self.isLoading = false
                self.tableView.footerProgressWorkingJobs -= 1
            } }
            let resp = source.req.requestNoteSearch(query: key, untilId: untilId)
            let build = curr + resp
            withMainActor {
                self.searchResult = build
            }
        }
    }
}

extension NoteSearchResultController: LLNavControllerAttachable {
    func createRightBarView() -> UIView? {
        let view = UIView()
        let indicator = UIActivityIndicatorView()
        view.addSubview(indicator)
        indicators.append(indicator)
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
