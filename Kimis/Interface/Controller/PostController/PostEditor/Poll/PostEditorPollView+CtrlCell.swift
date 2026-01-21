//
//  PostEditorPollView+CtrlCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/13.
//

import Combine
import Source
import UIKit

extension PostEditorPollView {
    class PollEditorControlCell: TableViewCell, UITextViewDelegate {
        static let cellId = "PollEditorControlCell"

        var post: Post?
        var spacing: CGFloat = 0 {
            didSet {
                selectionTypeButton.snp.updateConstraints { make in
                    make.left.equalTo(addChoiceButton.snp.right).offset(spacing)
                }
                dateButton.snp.updateConstraints { make in
                    make.left.equalTo(selectionTypeButton.snp.right).offset(spacing)
                }
            }
        }

        let heightMeasureTextView = TextView.noneInteractive()
        let container = UIView()
        let addChoiceButton = UIButton()
        let selectionTypeButton = UIButton()
        let selectionTypeDelegate = MultipleSelectionDelegate()
        let selectionMenuAnchor = UIView()
        let dateButton = UIButton()
        let dateButtonDelegate = DatePickerDelegate()
        let dateMenuAnchor = UIView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.clipsToBounds = true

            contentView.addSubview(heightMeasureTextView)

            heightMeasureTextView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            let textInset: CGFloat = 6
            heightMeasureTextView.layer.cornerRadius = IH.contentMiniItemCornerRadius
            heightMeasureTextView.backgroundColor = .accent.withAlphaComponent(0.1)
            heightMeasureTextView.textContainerInset = UIEdgeInsets(
                top: textInset,
                left: textInset,
                bottom: textInset,
                right: textInset,
            )
            heightMeasureTextView.isScrollEnabled = false
            heightMeasureTextView.font = .systemFont(ofSize: 16)
            heightMeasureTextView.text = "0xDEADBEEF"

            heightMeasureTextView.isHidden = true

            contentView.addSubview(container)
            container.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            let spacing: CGFloat = 4

            container.addSubview(addChoiceButton)
            addChoiceButton.snp.makeConstraints { make in
                make.width.equalTo(addChoiceButton.snp.height)
                make.left.equalToSuperview()
                make.top.bottom.equalToSuperview()
            }
            addChoiceButton.layer.cornerRadius = IH.contentMiniItemCornerRadius
            addChoiceButton.imageView?.contentMode = .scaleAspectFit
            addChoiceButton.imageView?.tintColor = .accent
            addChoiceButton.backgroundColor = .accent.withAlphaComponent(0.1)
            addChoiceButton.setImage(UIImage(systemName: "plus"), for: .normal)
            addChoiceButton.addTarget(self, action: #selector(addChoice), for: .touchUpInside)

            container.addSubview(selectionMenuAnchor)
            container.addSubview(selectionTypeButton)
            container.addSubview(dateMenuAnchor)
            container.addSubview(dateButton)

            selectionTypeButton.snp.makeConstraints { make in
                make.left.equalTo(addChoiceButton.snp.right).offset(spacing)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(selectionTypeButton.snp.height)
            }
            selectionTypeButton.layer.cornerRadius = IH.contentMiniItemCornerRadius
            selectionTypeButton.imageView?.contentMode = .scaleAspectFit
            selectionTypeButton.imageView?.tintColor = .accent
            selectionTypeButton.backgroundColor = .accent.withAlphaComponent(0.1)
            selectionTypeDelegate.getPost = { [weak self] in
                self?.post
            }

            let selectionInteraction = UIContextMenuInteraction(delegate: selectionTypeDelegate)
            selectionTypeButton.addInteraction(selectionInteraction)
            selectionTypeButton.addTarget(self, action: #selector(selectPollType), for: .touchUpInside)
            selectionMenuAnchor.snp.makeConstraints { make in
                make.edges.equalTo(selectionTypeButton)
            }
            selectionTypeDelegate.anchor = selectionMenuAnchor

            dateButton.snp.makeConstraints { make in
                make.left.equalTo(selectionTypeButton.snp.right).offset(spacing)
                make.top.bottom.equalToSuperview()
                make.right.equalToSuperview().offset(-40)
            }
            dateButton.layer.cornerRadius = IH.contentMiniItemCornerRadius
            dateButton.backgroundColor = .accent.withAlphaComponent(0.1)
            dateButton.titleLabel?.font = .systemFont(ofSize: 16)
            dateButton.titleEdgeInsets = .init(horizontal: 8, vertical: 0)
            dateButton.setTitleColor(.accent, for: .normal)
            dateButtonDelegate.getPost = { [weak self] in
                self?.post
            }
            let dateButtonInteraction = UIContextMenuInteraction(delegate: dateButtonDelegate)
            dateButton.addInteraction(dateButtonInteraction)
            dateButton.addTarget(self, action: #selector(selectDate), for: .touchUpInside)
            dateMenuAnchor.snp.makeConstraints { make in
                make.edges.equalTo(dateButton)
            }
            dateButtonDelegate.anchor = dateMenuAnchor

            updateButtonValues()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            post = nil
            cancellable.forEach { $0.cancel() }
            cancellable = []
        }

        func bind(post: Post) {
            self.post = post

            post.updated
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateButtonValues()
                }
                .store(in: &cancellable)
            updateButtonValues()
        }

        func updateButtonValues() {
            guard let post else { return }
            if post.poll?.multiple ?? false {
                selectionTypeButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
            } else {
                selectionTypeButton.setImage(UIImage(systemName: "1.circle"), for: .normal)
            }
            if let date = post.poll?.expiresAt {
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .abbreviated
                formatter.allowedUnits = [.day, .hour, .minute]
                let str = formatter.string(from: date.timeIntervalSinceNow) ?? L10n.text("Unknown")
                dateButton.setTitle(str, for: .normal)
            } else {
                dateButton.setTitle(L10n.text("Long Term"), for: .normal)
            }
        }

        @objc func addChoice() {
            HapticGenerator.make(.selectionChanged)
            if let post {
                if post.poll?.choices.count ?? 0 < 10 {
                    post.poll?.choices.append("")
                } else {
                    presentError(L10n.text("Can not add more"))
                }
            }
        }

        @objc func selectPollType() {
            HapticGenerator.make(.selectionChanged)
            selectionTypeButton.presentMenu()
        }

        @objc func selectDate() {
            HapticGenerator.make(.selectionChanged)
            dateButton.presentMenu()
        }
    }
}

extension PostEditorPollView.PollEditorControlCell {
    class DatePickerDelegate: NSObject, UIContextMenuInteractionDelegate {
        weak var anchor: UIView?
        var getPost: (() -> (Post?))?

        enum DateSelection: Double, CaseIterable {
            case _5m = 300
            case _30m = 1800
            case _60m = 3600
            case _6h = 21600
            case _1d = 86400
            case _3d = 259_200
            case _7d = 604_800
            case _distantFuture = -1

            var describe: String {
                let interval = rawValue
                if interval <= 0 { return L10n.text("Long Term") }
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .abbreviated
                formatter.allowedUnits = [.day, .hour, .minute]
                return formatter.string(from: TimeInterval(interval)) ?? L10n.text("Unknown")
            }
        }

        var dateSelection: DateSelection = ._1d

        func contextMenuInteraction(_: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration _: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let anchor else { return nil }
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .platformBackground
            parameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 0, height: 0), cornerRadius: 0)
            let preview = UITargetedPreview(view: anchor, parameters: parameters)
            return preview
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            guard let post = getPost?() else { return nil }
            return .init(identifier: nil, previewProvider: nil) { _ in
                let menus = DateSelection.allCases.map { dateSelection in
                    let describe = dateSelection.describe
                    return UIAction(title: describe) { _ in
                        if dateSelection.rawValue <= 5 {
                            post.poll?.expiresAt = nil
                        } else {
                            post.poll?.expiresAt = Date().addingTimeInterval(dateSelection.rawValue + 1)
                        }
                    }
                }
                return UIMenu(children: menus)
            }
        }
    }
}

extension PostEditorPollView.PollEditorControlCell {
    class MultipleSelectionDelegate: NSObject, UIContextMenuInteractionDelegate {
        weak var anchor: UIView?
        var getPost: (() -> (Post?))?

        func contextMenuInteraction(_: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration _: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let anchor else { return nil }
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .platformBackground
            parameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 0, height: 0), cornerRadius: 0)
            let preview = UITargetedPreview(view: anchor, parameters: parameters)
            return preview
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            guard let post = getPost?() else { return nil }
            return .init(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [
                    UIAction(title: L10n.text("Single Choice"), image: UIImage(systemName: "1.circle")) { _ in
                        post.poll?.multiple = false
                    },
                    UIAction(title: L10n.text("Multiple Choice"), image: UIImage(systemName: "list.bullet")) { _ in
                        post.poll?.multiple = true
                    },
                ])
            }
        }
    }
}
