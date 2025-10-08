//
//  NoteTableView+Delegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import UIKit

extension NoteTableView: UITableViewDelegate, UITableViewDataSource {
    func retainContext(atIndexPath indexPath: IndexPath) -> NoteCell.Context? {
        assert(Thread.isMainThread)
        return context[safe: indexPath.row]
    }

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        context.count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = retainContext(atIndexPath: indexPath) else {
            assertionFailure()
            return .init()
        }
        guard let cell = dequeueReusableCell(withIdentifier: data.kind.cellId, for: indexPath) as? NoteCell else {
            assertionFailure()
            return .init()
        }
        cell.load(data: data)
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let data = retainContext(atIndexPath: indexPath) else {
            assertionFailure()
            return 0
        }
        return data.cellHeight
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        withMainActor(delay: 0.1) {
            self.deselectRow(at: indexPath, animated: true)
        }
        guard let data = retainContext(atIndexPath: indexPath),
              let noteId = data.noteId
        else {
            return
        }
        source?.timeline.pointOfInterest = data.noteId
        didSelect(noteId)
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let id = retainContext(atIndexPath: indexPath)?.noteId {
            displayingCells.insert(id)
        }
    }

    func tableView(_: UITableView, didEndDisplaying _: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let id = retainContext(atIndexPath: indexPath)?.noteId {
            displayingCells.remove(id)
        }
    }

    var itemCount: Int {
        var count = 0
        for item in context where !item.kind.isSupplymentKind {
            count += 1
        }
        return count
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        guard let footer = dequeueReusableHeaderFooterView(
            withIdentifier: FooterCountView.identifier
        ) as? FooterCountView else {
            return nil
        }
        let count = itemCount
        if count > 0 {
            footer.set(title: L10n.text("%d note(s)", count))
        } else {
            footer.set(title: L10n.text("🥲 Nothing Here"))
        }
        return footer
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        FooterCountView.footerHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        self.tableView(tableView, heightForFooterInSection: section)
    }
}
