//
//  UserSimpleBannerCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import Combine
import Source
import UIKit

class UserSimpleBannerCell: TableViewCell {
    static let id = "UserSimpleBannerCell"

    static let padding: CGFloat = IH.preferredViewPadding()

    let container: UIView = .init()

    let preview = UserSimpleBannerView()

    var context: Context?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(container)
        container.addSubview(preview)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = contentView.bounds
        let width = IH.containerWidth(usingWidth: bounds.width)
        let paddingInset = max(UserCell.padding, (bounds.width - width) / 2)
        container.frame = CGRect(
            x: paddingInset,
            y: 0,
            width: width - 2 * paddingInset,
            height: bounds.height
        )
        preview.frame = container.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        context = nil
        contentView.backgroundColor = .clear
        preview.snapshot = nil
    }

    func load(_ context: Context) {
        self.context = context
        guard let snapshot = context.snapshot as? UserSimpleBannerView.Snapshot else {
            assertionFailure()
            return
        }
        preview.snapshot = snapshot
    }
}
