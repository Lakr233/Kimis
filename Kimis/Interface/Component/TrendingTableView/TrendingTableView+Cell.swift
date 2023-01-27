//
//  TrendingTableView+Cell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import UIKit

extension TrendingTableView {
    class ItemCell: TableViewCell {
        static let identifier = "cell"
        static let cellHeight: CGFloat = 60

        let icon = UIImageView()
        let title = UILabel()
        let subtitle = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            backgroundColor = .clear

            contentView.addSubview(icon)
            contentView.addSubview(title)
            contentView.addSubview(subtitle)

            let padding: CGFloat = IH.preferredViewPadding()

            icon.contentMode = .scaleAspectFit
            icon.tintColor = .accent
            icon.image = UIImage(systemName: "number")

            icon.snp.makeConstraints { make in
                make.left.top.bottom.equalToSuperview().inset(padding)
                make.width.equalTo(20)
            }
            title.font = .systemFont(ofSize: 16, weight: .bold)
            title.textColor = .systemBlackAndWhite
            title.snp.makeConstraints { make in
                make.left.equalTo(icon.snp.right).offset(padding)
                make.bottom.equalTo(icon.snp.centerY).offset(4)
                make.right.equalToSuperview().offset(-padding)
            }
            subtitle.textColor = .systemBlackAndWhite.withAlphaComponent(0.5)
            subtitle.font = .systemFont(ofSize: 14, weight: .regular)
            subtitle.snp.makeConstraints { make in
                make.top.equalTo(title.snp.bottom).offset(2)
                make.left.equalTo(title.snp.left)
                make.right.equalToSuperview().offset(-padding)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            title.text = ""
            subtitle.text = ""
        }

        func load(_ trending: Trending) {
            title.text = trending.tag
            subtitle.text = "\(trending.usersCount) user(s)"
        }
    }
}
