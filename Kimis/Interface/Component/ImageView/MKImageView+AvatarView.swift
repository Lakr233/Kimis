//
//  MKImageView+AvatarView.swift
//  main
//
//  Created by Lakr Aream on 2022/5/14.
//

import Combine
import Source
import UIKit

class AvatarView: MKRoundedImageView {
    override init() {
        super.init()

        renderView.imageView.layer.minificationFilter = .trilinear
        layer.borderWidth = 0.1
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
    }
}

class AccountAvatarView: AvatarView {
    weak var source: Source? = Account.shared.source
    private var cancellables: Set<AnyCancellable> = []

    let button = UIButton()
    var tappable = true

    override init() {
        super.init()
        layer.minificationFilter = .trilinear

        addSubview(button)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        source?.$user
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.updateAvatar(with: value)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAvatar(with profile: UserProfile) {
        let payload = MKImageView.Request(url: profile.avatarUrl, blurHash: profile.avatarBlurhash)
        loadImage(with: payload)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
    }

    @objc func buttonTapped() {
        guard tappable else { return }
        shineAnimation()
        ControllerRouting.pushing(tag: .me, referencer: self, associatedData: nil)
    }
}
