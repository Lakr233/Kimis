//
//  UsersListTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import Combine
import Source
import UIKit

class UserSimpleBannerListTableView: TableView, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    @Published var users: [UserProfile] = []
    @Published var layoutWidth: CGFloat = 0
    @Published var scrollOffset: CGPoint = .zero
    let refreshCaller = CurrentValueSubject<Bool, Never>(true)

    let progressView = ProgressFooterView()

    var _source: [UserSimpleBannerCell.Context] = [] {
        didSet { reloadData() }
    }

    let renderQueue = DispatchQueue(label: "wiki.qaq.render.user.list")

    override init() {
        super.init()

        tableFooterView = progressView
        tableFooterView?.frame.size.height = progressView.intrinsicContentSize.height

        register(UserSimpleBannerCell.self, forCellReuseIdentifier: UserCell.id)
        register(FooterCountView.self, forHeaderFooterViewReuseIdentifier: FooterCountView.identifier)

        delegate = self
        dataSource = self

        Publishers.CombineLatest3(
            $users
                .removeDuplicates()
                .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global()),
            $layoutWidth
                .removeDuplicates()
                .filter { $0 > 0 }
                .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global()),
            refreshCaller
        )
        .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
        .receive(on: renderQueue)
        .sink { [weak self] input in
            guard let self else { return }
            withMainActor {
                self.progressView.animate()
            }
            let context = input.0.map { UserSimpleBannerCell.Context(user: $0) }
            let width = input.1
            context.forEach { $0.renderLayout(usingWidth: width - 2 * UserCell.padding) }
            withMainActor {
                self._source = context
                self.progressView.stopAnimate()
            }
        }
        .store(in: &cancellable)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if layoutWidth != bounds.width {
            renderVisibleCellAndUpdate()
            layoutWidth = bounds.width
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        _source.count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: UserCell.id, for: indexPath) as! UserSimpleBannerCell
        if let ctx = _source[safe: indexPath.row] {
            cell.load(ctx)
        } else {
            cell.prepareForReuse()
        }
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        _source[indexPath.row].cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let user = _source[safe: indexPath.row]?.profile else { return }
        ControllerRouting.pushing(tag: .user, referencer: self, associatedData: user.userId)
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        guard let footer = dequeueReusableHeaderFooterView(
            withIdentifier: FooterCountView.identifier
        ) as? FooterCountView else {
            return nil
        }
        if _source.count > 0 {
            footer.set(title: "\(_source.count) users(s)")
        } else {
            footer.set(title: "No User Data")
        }
        return footer
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        FooterCountView.footerHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        self.tableView(tableView, heightForFooterInSection: section)
    }

    func renderVisibleCellAndUpdate() {
        let visibleIndexPaths = indexPathsForVisibleRows ?? []
        for indexPath in visibleIndexPaths {
            if let ctx = _source[safe: indexPath.row] {
                ctx.renderLayout(usingWidth: bounds.width - 2 * UserCell.padding)
            }
        }
        beginUpdates()
        for indexPath in visibleIndexPaths {
            guard let cell = cellForRow(at: indexPath) as? UserSimpleBannerCell else {
                continue
            }
            guard let ctx = _source[safe: indexPath.row] else {
                continue
            }
            cell.load(ctx)
        }
        endUpdates()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset
    }
}
