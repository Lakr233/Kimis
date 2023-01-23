//
//  TableViewCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/8.
//

import Combine
import Source
import UIKit

class TableViewCell: UITableViewCell {
    weak var source: Source? = Account.shared.source
    var cancellable = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
