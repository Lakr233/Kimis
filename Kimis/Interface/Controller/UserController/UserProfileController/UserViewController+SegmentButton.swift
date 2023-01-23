//
//  UserViewController+SegmentButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/28.
//

import UIKit

extension UserViewController.ProfileView {
    class SegmentButton: UIView {
        static let height: CGFloat = 40

        var tapped: () -> Void = {}
        let button = UIButton()

        init(title: String) {
            super.init(frame: .zero)

            addSubview(button)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: #selector(touch), for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            layer.cornerRadius = 6

            updateAppearance()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var highlight: Bool = false {
            didSet { updateAppearance() }
        }

        func updateAppearance() {
            withUIKitAnimation {
                self._updateAppearance()
            }
        }

        private func _updateAppearance() {
            if highlight {
                button.setTitleColor(.accent, for: .normal)
                backgroundColor = .accent.withAlphaComponent(0.1)
            } else {
                button.setTitleColor(.systemBlackAndWhite, for: .normal)
                backgroundColor = .separator.withAlphaComponent(0.5)
            }
        }

        @objc func touch() {
            puddingAnimate()
            tapped()
        }
    }
}
