//
//  NoteCell+Separator.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import UIKit

extension NoteCell {
    class Separator: NoteCell {
        let sep = UIView()

        override var canBecomeFocused: Bool { false }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            container.addSubview(sep)
            sep.backgroundColor = .separator.withAlphaComponent(0.5)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let bounds = container.bounds
            sep.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        }
    }
}
