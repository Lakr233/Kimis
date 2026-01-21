//
//  ChoiceView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/1.
//

import Source
import UIKit

extension PollView {
    class ChoiceView: UIView {
        weak var source: Source? = Account.shared.source

        var snapshot: Snapshot? {
            didSet {
                if snapshot != oldValue { updateDataSource() }
            }
        }

        let indicator = UIActivityIndicatorView()
        var isVoting = false {
            didSet { layoutSubviews() }
        }

        static var defaultBackgroundColor: UIColor {
            UIColor.accent.withAlphaComponent(0.1)
        }

        let votePercentBackground = UIView()

        let iconView = UIImageView()
        let textView = TextView.noneInteractive()
        let countTextView = TextView.noneInteractive()

        let button = UIButton()

        init() {
            super.init(frame: .zero)

            addSubviews([
                votePercentBackground,
                iconView, indicator,
                textView,
                countTextView,
            ])

            iconView.contentMode = .scaleAspectFit

            backgroundColor = Self.defaultBackgroundColor
            votePercentBackground.backgroundColor = Self.defaultBackgroundColor

            layer.cornerRadius = IH.contentMiniItemCornerRadius
            clipsToBounds = true

            addSubview(button)
            button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let snapshot {
                iconView.frame = snapshot.iconRect
                textView.frame = snapshot.textRect
                countTextView.frame = snapshot.countTextRect
                votePercentBackground.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: bounds.width * snapshot.element.percent,
                    height: bounds.height,
                )
            } else {
                iconView.frame = .zero
                textView.frame = .zero
                countTextView.frame = .zero
                votePercentBackground.frame = .zero
            }
            indicator.frame.size = indicator.intrinsicContentSize
            indicator.center = iconView.center
            if isVoting {
                indicator.isHidden = false
                indicator.startAnimating()
                iconView.isHidden = true
            } else {
                indicator.isHidden = true
                indicator.stopAnimating()
                iconView.isHidden = false
            }
            button.frame = bounds
        }

        func clear() {
            iconView.image = nil
            textView.attributedText = nil
            countTextView.attributedText = nil
        }

        func updateDataSource() {
            clear()
            guard let snapshot else { return }
            iconView.image = snapshot.element.isVoted
                ? .init(systemName: "checkmark.circle.fill")
                : (
                    snapshot.interactive
                        ? .init(systemName: "circle")
                        : .init(systemName: "xmark.circle")
                )
            textView.attributedText = snapshot.text
            countTextView.attributedText = snapshot.countText

            setNeedsLayout()
        }

        @objc func tapped() {
            guard snapshot?.interactive ?? false, !isVoting else { return }

            guard let noteId = snapshot?.noteId, let idx = snapshot?.index else {
                return
            }
            guard let element = snapshot?.element, !element.isVoted else {
                return
            }

            guard let source else { return }

            backgroundColor = .clear
            withUIKitAnimation { self.backgroundColor = Self.defaultBackgroundColor }

            let alert = UIAlertController(
                title: L10n.text("Vote"),
                message: L10n.text("Are you sure you want to vote for %@?", element.text),
                preferredStyle: .alert,
            )
            alert.addAction(UIAlertAction(title: L10n.text("Yes"), style: .default, handler: { [weak self] _ in
                print("[*] vote note \(noteId) idx \(idx)")
                self?.isVoting = true
                DispatchQueue.global().async {
                    source.req.requestNotePollVote(forNote: noteId, choiceIndex: idx)
                    withMainActor(delay: 1.0) { [weak self] in
                        self?.isVoting = false
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: L10n.text("No"), style: .cancel))
            parentViewController?.present(alert, animated: true)
        }
    }
}
