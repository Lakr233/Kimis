//
//  ReactionStrip+UserList.swift
//  Kimis
//
//  Created by QAQ on 2023/7/19.
//

import UIKit

extension ReactionStrip {
    class UserListPopover: ViewController, UIPopoverPresentationControllerDelegate {
        let contentView = UIView()
        let reactionElement: ReactionElement

        let activityIndicator = UIActivityIndicatorView()
        let tableView = UsersListTableView()
        var userList: [User] = [] { didSet {
            view.setNeedsLayout()
        } }

        // TODO: Current Api has limit for 100 users, make more!

        init(sourceView: UIView, representReaction: ReactionElement) {
            reactionElement = representReaction
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .popover
            preferredContentSize = CGSize(width: 400, height: 300)
            popoverPresentationController?.delegate = self
            popoverPresentationController?.sourceView = sourceView
            let padding: CGFloat = 4
            popoverPresentationController?.sourceRect = .init(
                x: -padding,
                y: -padding,
                width: sourceView.frame.width + padding * 2,
                height: sourceView.frame.height + padding * 2
            )
            popoverPresentationController?.permittedArrowDirections = .any
            view.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            tableView.alpha = 0
            contentView.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
            contentView.addSubview(activityIndicator)
            activityIndicator.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            activityIndicator.startAnimating()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            loadUserList()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func adaptivePresentationStyle(
            for _: UIPresentationController,
            traitCollection _: UITraitCollection
        ) -> UIModalPresentationStyle {
            .none
        }

        func loadUserList() {
            var reactionIdentifier: String?
            if let representReaction = reactionElement.representImageReaction {
                reactionIdentifier = ":\(representReaction):"
            } else if let textEmoji = reactionElement.text {
                reactionIdentifier = textEmoji
            }

            guard let reactionIdentifier,
                  let source = Account.shared.source
            else { return }
            let noteId = reactionElement.noteId

            DispatchQueue.global().async {
                let userList = source.req.requestNoteReactionUserList(
                    reactionIdentifier: reactionIdentifier,
                    forNote: noteId
                )
                DispatchQueue.main.async {
                    self.tableView.users = userList.compactMap { .converting($0) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withUIKitAnimation {
                            self.activityIndicator.alpha = 0
                            self.tableView.alpha = 1
                        } completion: {
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.isHidden = true
                        }
                    }
                }
            }
        }
    }
}
