//
//  PostButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import UIKit

class PostButton: UIView {
    @DefaultButton
    var button: UIButton
    let imageView = UIImageView()

    init() {
        super.init(frame: .zero)
        backgroundColor = .accent

        addSubview(imageView)
        imageView.image = UIImage.fluent(.calligraphy_pen_filled)
        imageView.tintColor = .white
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.center.equalToSuperview()
        }
        addSubview(button)
        button.addTarget(self, action: #selector(preparePost), for: .touchUpInside)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = (bounds.width + bounds.height) / 4
    }

    @objc func preparePost() {
        shineAnimation()
        ControllerRouting.pushing(tag: .post, referencer: self, associatedData: nil)
    }
}
