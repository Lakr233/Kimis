//
//  TimelineController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/4/29.
//

import Combine
import SnapKit
import Source
import SPIndicator
import UIKit

class TimelineController: ViewController {
    let updateMoreRequestSubject = CurrentValueSubject<Bool, Never>(true)

    let tableView = TimelineTableView()
    let guider = NoteTableView.NewItemGuider()
    let refreshControl = UIRefreshControl()

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Timeline"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        view.clipsToBounds = false
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(guider)
        tableView.guider = guider
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
                guard !(self?.source?.timeline.updating ?? true) else { return }
                self?.source?.timeline.requestUpdate(direction: .older)
            }
            .store(in: &tableView.cancellable)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let bounds = view.bounds
        let guiderSize = guider.intrinsicContentSize
        guider.frame = CGRect(
            x: bounds.width - guiderSize.width - IH.preferredPadding(usingWidth: bounds.width) - view.safeAreaInsets.right,
            y: IH.preferredPadding(usingWidth: bounds.width) + view.safeAreaInsets.top,
            width: guiderSize.width,
            height: guiderSize.height
        )
    }

    @objc func refreshControlValueChanged() {
        withMainActor(delay: 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.source?.timeline.requestUpdate(direction: .newer)
        }
    }

    func didScroll(toPosition offset: CGFloat) {
        if offset > tableView.contentSize.height - tableView.frame.height - 10, !(source?.timeline.updating ?? true) {
            updateMoreRequestSubject.send(true)
        }
    }
}
