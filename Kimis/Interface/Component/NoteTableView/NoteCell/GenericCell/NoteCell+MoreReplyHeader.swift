//
//  NoteCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class MoreReplyHeaderCell: MoreHeaderCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            icon.image = .fluent(.arrow_maximize_vertical_filled)
            label.text = "Expend Collapsed Replies"
        }
    }
}
