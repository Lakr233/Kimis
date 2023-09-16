//
//  FooterCountView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import UIKit

class FooterCountView: UITableViewHeaderFooterView {
    let label = UILabel()

    static let identifier = "footer"
    static let footerHeight: CGFloat = 128

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        label.textAlignment = .center
        label.textColor = .systemBlackAndWhite.withAlphaComponent(0.25)
        label.font = .rounded(ofSize: 12, weight: .semibold)
        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(horizontal: 12, vertical: 0)
            )
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
    }

    func set(title: String) {
        label.text = title
    }
}
