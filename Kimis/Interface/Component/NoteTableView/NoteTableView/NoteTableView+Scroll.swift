//
//  NoteTableView+Scroll.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/19.
//

import UIKit

extension NoteTableView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollLocation = scrollView.contentOffset
//        print(scrollView.contentOffset)
    }

    @discardableResult
    func scrollTo(note: NoteID, animated: Bool = true, atRelativePosition pos: UITableView.ScrollPosition = .top) -> Bool {
        assert(Thread.isMainThread)
        for (idx, item) in context.enumerated() {
            if item.noteId == note {
                scrollToRow(at: IndexPath(row: idx, section: 0), at: pos, animated: animated)
                return true
            }
        }
        return false
    }
}
