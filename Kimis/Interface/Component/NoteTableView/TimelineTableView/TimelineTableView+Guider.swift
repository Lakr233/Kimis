//
//  NoteTableView+Guider.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/5.
//

import Combine
import MorphingLabel
import UIKit

extension TimelineTableView {
    func presentNewItemGuider() {
        if guider?.button.allTargets.isEmpty ?? false {
            guider?.button.defaultButton()
            guider?.button.addTarget(self, action: #selector(guiderButtonTapped), for: .touchUpInside)
        }
        withMainActor(delay: 0.2) { self.guider?.present() }
    }

    @objc private func guiderButtonTapped() {
        let indexPath = IndexPath(row: 0, section: 0)
        if isExist(indexPath: indexPath) {
            scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    func updateGuiderCount() {
        guard let guider else { return }

        var decisionIndex: IndexPath?

        var contentShift: CGFloat = 0
        if let header = tableHeaderView?.frame.height {
            contentShift += header
        }
        if parentViewController?.edgesForExtendedLayout.contains(.top) ?? false,
           let safeHeight = superview?.safeAreaInsets.top
        {
            contentShift += safeHeight
        }
        for item in indexPathsForVisibleRows ?? [] {
            let rect = rectForRow(at: item)
            guard rect.minY >= visibleRect.minY + contentShift else { continue }
            decisionIndex = item
            break
        }

        guard let decisionIndex else { return }

        let row = decisionIndex.row
        var count = 0
        if row > 0 {
            for rowIdx in 0 ..< row {
                guard let ctx = retainContext(atIndexPath: IndexPath(row: rowIdx, section: 0)),
                      !ctx.kind.isSupplymentKind
                else {
                    continue
                }
                count += 1
            }
        }
        guider.count = count
    }
}

extension NoteTableView {
    class NewItemGuider: UIView {
        override var intrinsicContentSize: CGSize {
            CGSize(width: 48, height: 24)
        }

        let wrapper: UIVisualEffectView = {
            let effect = UIBlurEffect(style: .systemThinMaterial)
            return .init(effect: effect)
        }()

        let icon = UIImageView()
        let label = LTMorphingLabel()
        let button = UIButton()

        private var _realCount: Int = 0

        var count: Int {
            set {
                _realCount = min(newValue, _realCount)
                updateCount()
            }
            get { _realCount }
        }

        func setCountMax(_ cnt: Int, appending: Bool = false) {
            _realCount = cnt + (appending ? _realCount : 0)
        }

        override init(frame _: CGRect) {
            super.init(frame: .zero)

            wrapper.backgroundColor = .white.withAlphaComponent(0.5)
            wrapper.alpha = 0
            addSubview(wrapper)

            wrapper.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(-50)
                make.centerX.equalToSuperview()
                make.width.equalTo(self.intrinsicContentSize.width)
                make.height.equalTo(self.intrinsicContentSize.height)
            }

            wrapper.contentView.addSubview(icon)
            wrapper.contentView.addSubview(label)

            icon.tintColor = .accent
            icon.contentMode = .scaleAspectFit
            icon.image = UIImage(systemName: "arrow.up")
            icon.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(8)
                make.width.height.equalTo(12)
            }

            label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
            label.textColor = .accent
            label.textAlignment = .center
            label.morphingEffect = .evaporate
            label.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-8)
                make.left.equalTo(icon.snp.right).offset(0)
                make.top.bottom.equalToSuperview()
            }

            wrapper.contentView.addSubview(button)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            wrapper.clipsToBounds = true
            wrapper.layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                UIView.performWithoutAnimation {
                    updateCount()
                }
            }
        }

        func updateCount() {
            if count > 99 {
                label.text = "++"
            } else {
                label.text = String(count)
            }
            if count <= 0 {
                label.text = ""
                dismiss()
            }
        }

        func present() {
            if count <= 0 {
                dismiss()
                return
            }
            withUIKitAnimation { [self] in
                wrapper.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(0)
                }
                wrapper.alpha = 1
                layoutIfNeeded()
            }
        }

        func dismiss() {
            withUIKitAnimation { [self] in
                wrapper.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(-50)
                }
                wrapper.alpha = 0
                layoutIfNeeded()
            }
        }
    }
}
