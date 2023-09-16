//
//  TrendingTableView+Delegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import Combine
import UIKit

extension TrendingTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        _source.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ItemCell.identifier,
            for: indexPath
        ) as? ItemCell else {
            assertionFailure()
            return .init()
        }
        guard let data = _source[safe: indexPath.row] else { return cell }
        cell.load(data)
        return cell
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        guard let footer = dequeueReusableHeaderFooterView(
            withIdentifier: FooterCountView.identifier
        ) as? FooterCountView else {
            return nil
        }
        if _source.count > 0 {
            footer.set(title: "\(_source.count) trending hashtag(s)")
        } else {
            footer.set(title: "No Trending Data")
        }
        return footer
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        FooterCountView.footerHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        self.tableView(tableView, heightForFooterInSection: section)
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        ItemCell.cellHeight
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        withMainActor(delay: 0.1) {
            self.deselectRow(at: indexPath, animated: true)
        }
        guard let data = _source[safe: indexPath.row] else { return }
        ControllerRouting.pushing(tag: .hashtag, referencer: self, associatedData: data.tag)
    }
}
