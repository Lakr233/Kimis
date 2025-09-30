//
//  ReactionStrip+BaseView.swift
//  Kimis
//
//  Created by QAQ on 2023/7/17.
//

import UIKit

extension ReactionStrip {
    class ElementBaseView: UIView, UIContextMenuInteractionDelegate {
        var representReaction: ReactionElement?
        let button = UIButton()

        let contentView = UIView()
        let emojiContainer = UIView()
        let countView: UILabel = {
            let view = UILabel()
            view.textAlignment = .center
            view.layer.cornerRadius = 6
            view.clipsToBounds = true
            view.layer.masksToBounds = true
            view.numberOfLines = 1
            view.minimumScaleFactor = 0.5
            view.adjustsFontSizeToFitWidth = true
            view.font = .rounded(ofSize: 16, weight: .regular)
            return view
        }()

        let activityIndicator = UIActivityIndicatorView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(contentView)
            addSubview(activityIndicator)
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true

            contentView.addSubview(emojiContainer)
            contentView.addSubview(countView)

            addSubview(button)
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
            button.addGestureRecognizer(longPress)
            button.addInteraction(UIContextMenuInteraction(delegate: self))
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            button.frame = bounds
            activityIndicator.frame = bounds
            contentView.frame = bounds
            bringSubviewToFront(button)

            emojiContainer.frame = CGRect(
                x: 0,
                y: 0,
                width: contentView.bounds.width / 2,
                height: contentView.bounds.height
            ).inset(by: .init(inset: 4))
            countView.frame = CGRect(
                x: contentView.bounds.width / 2,
                y: 0,
                width: contentView.bounds.width / 2,
                height: contentView.bounds.height
            )
        }

        @objc func buttonTapped() {
            puddingAnimate()
            beginProgress {
                guard let source = Account.shared.source,
                      let reactionElement = self.representReaction
                else { return }
                if reactionElement.isUserReaction {
                    _ = source.req.requestNoteReaction(reactionIdentifier: nil, forNote: reactionElement.noteId)
                } else if let representReaction = reactionElement.representImageReaction {
                    var lookup = false
                    if !lookup,
                       source.emojis.keys.contains(representReaction)
                    { lookup = true }
                    if !lookup,
                       representReaction.hasSuffix("@."),
                       source.emojis.keys.contains(String(representReaction.dropLast(2)))
                    { lookup = true }
                    if lookup {
                        _ = source.req.requestNoteReaction(
                            reactionIdentifier: ":\(representReaction):",
                            forNote: reactionElement.noteId
                        )
                    } else {
                        presentError("This reaction is not available")
                    }
                } else if let textEmoji = reactionElement.text {
                    _ = source.req.requestNoteReaction(
                        reactionIdentifier: textEmoji,
                        forNote: reactionElement.noteId
                    )
                } else {
                    presentError("Unable to find this reaction")
                }
            }
        }

        func beginProgress(executnigInBackground: @escaping () -> Void) {
            assert(Thread.isMainThread)
            contentView.isHidden = true
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            DispatchQueue.global().async {
                executnigInBackground()
                // so refresh can go without blink~
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.contentView.isHidden = false
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }

        @objc func longPress(_: UILongPressGestureRecognizer) {
            // eat this event, let context menu to handle
//            if guesture.state == .began { postLongPress() }
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            postLongPress()
            return nil
        }

        func postLongPress() {
            guard let representReaction else { return }
            let controller = UserListPopover(sourceView: self, representReaction: representReaction)
            window?.topController?.present(controller, animated: true)
        }
    }
}
