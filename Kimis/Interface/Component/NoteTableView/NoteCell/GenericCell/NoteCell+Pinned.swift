//
//  NoteCell+Pinned.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import UIKit

extension NoteCell {
    class PinnedCell: MainCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            preview.pinned = true
        }
    }
}
