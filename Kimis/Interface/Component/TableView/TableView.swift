//
//  TableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/29.
//

import Combine
import UIKit

class TableView: UITableView {
    weak var source: Source? = Account.shared.source
    var cancellable = Set<AnyCancellable>()

    init() {
        super.init(frame: .zero, style: .plain)

        clipsToBounds = false

        backgroundColor = .clear
        separatorColor = .clear
        separatorStyle = .none

        estimatedRowHeight = 0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reloadData() {
        UIView.performWithoutAnimation {
            super.reloadData()

            if self.window != nil {
                setNeedsLayout()
                layoutIfNeeded()
            } else {
                print("[*] table view is calling reload when not visible, skip layout pass")
            }
        }
    }

    @objc
    var allowsFooterViewsToFloat: Bool {
        false
    }
}
