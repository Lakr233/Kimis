//
//  MKImageView+Rounded.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

class MKRoundedImageView: MKImageView {
    private var previousSize: CGSize = .zero

    init() {
        super.init()
        backgroundColor = .separator
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != frame.size {
            previousSize = frame.size
            layer.cornerRadius = frame.size.width / 2
        }
    }
}
