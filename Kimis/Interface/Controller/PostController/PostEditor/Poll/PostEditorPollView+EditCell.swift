//
//  PostEditorPollView+EditCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/13.
//

import Combine
import Source
import UIKit

extension PostEditorPollView {
    class PollEditorCell: TableViewCell, UITextViewDelegate {
        static let cellId = "PollEditorCell"

        let container = UIView()
        let textView = TextView(editable: true, selectable: true, disableLink: false)
        let placeholder = TextView.noneInteractive()
        let deleteButton = UIButton()

        var spacing: CGFloat = 0 {
            didSet {
                container.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-spacing)
                }
            }
        }

        var post: Post?
        var index: Int?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.clipsToBounds = true
            contentView.addSubview(container)
            container.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.bottom.equalToSuperview().offset(0)
            }

            container.addSubview(textView)
            container.addSubview(placeholder)
            container.addSubview(deleteButton)

            textView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalTo(deleteButton.snp.left).offset(-8)
            }
            placeholder.snp.makeConstraints { make in
                make.edges.equalTo(textView)
            }
            deleteButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(32)
                make.height.equalTo(32)
                make.right.equalToSuperview()
            }

            let textInset: CGFloat = 6
            textView.layer.cornerRadius = IH.contentMiniItemCornerRadius
            textView.backgroundColor = .accent.withAlphaComponent(0.1)
            textView.textContainerInset = UIEdgeInsets(
                top: textInset,
                left: textInset,
                bottom: textInset,
                right: textInset,
            )
            textView.isScrollEnabled = false
            textView.font = .systemFont(ofSize: 16)
            textView.delegate = self

            placeholder.textColor = .systemGray.withAlphaComponent(0.5)
            placeholder.textContainerInset = textView.textContainerInset
            placeholder.isUserInteractionEnabled = false
            placeholder.font = .systemFont(ofSize: 16)

            deleteButton.imageView?.contentMode = .scaleAspectFit
            deleteButton.layer.cornerRadius = IH.contentMiniItemCornerRadius
            deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
            deleteButton.addTarget(self, action: #selector(deleteThisItem), for: .touchUpInside)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            post = nil
            index = nil
            textView.text = nil
            placeholder.text = nil
            placeholder.alpha = 0

            cancellable.forEach { $0.cancel() }
            cancellable = []
        }

        func bind(post: Post, index: Int) {
            self.post = post
            self.index = index
            syncValue()
        }

        func syncValue() {
            guard let post, let index else {
                prepareForReuse()
                return
            }

            let deleteEnabled = post.poll?.choices.count ?? 0 > 2
            deleteButton.isEnabled = deleteEnabled
            deleteButton.imageView?.tintColor = deleteEnabled ? .systemPink : .gray

            let text = post.poll?.choices[safe: index] ?? ""
            if textView.text != text { textView.text = text }

            placeholder.text = "\(index + 1)"
            textViewDidChange(textView)
        }

        func textViewDidChange(_ textView: UITextView) {
            textView.sizeToFit()
            placeholder.alpha = textView.text.count > 0 ? 0 : 1
            guard let index, post?.poll?.choices[safe: index] != nil else {
                return
            }
            if post?.poll?.choices[index] != textView.text {
                post?.poll?.choices[index] = textView.text
            }
        }

        func textViewDidEndEditing(_: UITextView) {
            replaceAttributeForTextView()
        }

        func replaceAttributeForTextView() {
            textView.executeFocusedUpdate { textView in
                textView.font = .systemFont(ofSize: 16)
                textView.textColor = .systemBlackAndWhite
            }
        }

        @objc func deleteThisItem() {
            if let index, post?.poll?.choices[safe: index] != nil {
                post?.poll?.choices.remove(at: index)
            }
            syncValue()
        }
    }
}
