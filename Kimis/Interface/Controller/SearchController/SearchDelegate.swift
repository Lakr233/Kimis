//
//  SearchController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import Combine
import UIKit

class SearchDelegate: NSObject, UISearchBarDelegate {
    weak var anchor: UIView?

    init(anchor: UIView? = nil) {
        self.anchor = anchor
        super.init()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        finalizeSearchRequest(text: searchBar.text)
    }

    func finalizeSearchRequest(text: String?) {
        let key = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty else { return }

        if key.hasPrefix("@") {
            ControllerRouting.pushing(
                tag: .user,
                referencer: anchor,
                associatedData: key
            )
            return
        }

        let controller = NoteSearchResultController(searchKey: key)
        guard let vc = anchor?.parentViewController else {
            return
        }
        if let nav = vc.navigationController {
            nav.pushViewController(controller, animated: true)
        } else {
            vc.present(next: controller)
        }
    }
}
