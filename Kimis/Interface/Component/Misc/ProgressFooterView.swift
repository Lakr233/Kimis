//
//  ProgressFooterView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import Combine
import UIKit

class ProgressFooterView: UIView {
    private let indicator = UIActivityIndicatorView()

    override var intrinsicContentSize: CGSize {
        CGSize(width: 100, height: 100)
    }

    init() {
        super.init(frame: .zero)
        addSubview(indicator)
    }

    func animate() {
        assert(Thread.isMainThread)
        indicator.startAnimating()
    }

    func stopAnimate() {
        assert(Thread.isMainThread)
        indicator.stopAnimating()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let indicatorSize = indicator.intrinsicContentSize
        indicator.frame = CGRect(
            x: bounds.width / 2 - indicatorSize.width / 2,
            y: 20,
            width: indicatorSize.width,
            height: indicatorSize.height,
        )
    }
}
