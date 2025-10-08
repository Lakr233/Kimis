//
//  UserViewController+ProfileButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import Source
import UIKit

private let buttonHorizontalInset = CGFloat(10)

extension UserViewController.ProfileView {
    class ProfileButton: UIView {
        weak var source: Source? = Account.shared.source

        var profile: UserProfile? { didSet {
            updateDataSource()
            setNeedsLayout()
        } }

        init() {
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        var buttonViews: [ActionButton] = []

        func updateDataSource() {
            removeSubviews()
            buttonViews.removeAll()
            guard let profile, let source else { return }
            buttonViews = Self.buttons
                .filter { $0.qualification(source, profile) }
                .map { ActionButton(describingAction: $0, source: source, profile: profile) }
                + [ActionButtonForMore(source: source, profile: profile)]
            addSubviews(buttonViews)

            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let this = self
            let bounds = this.bounds

            let spacing: CGFloat = buttonHorizontalInset
            var anchor: CGFloat = bounds.width
            let buttonHeight: CGFloat = bounds.height - buttonHorizontalInset

            // layout from right to left
            for button in buttonViews {
                var width: CGFloat = 120
                if let text = button.button.titleLabel?.attributedText {
                    width = text.measureWidth() + buttonHorizontalInset * 2
                }
                button.frame = CGRect(
                    x: anchor - width,
                    y: bounds.maxY - buttonHeight,
                    width: width,
                    height: buttonHeight
                )
                anchor -= (button.frame.width + spacing)
            }
        }
    }
}

extension UserViewController.ProfileView.ProfileButton {
    struct ProgressHandler {
        let startAnimate: () -> Void
        let stopAnimate: () -> Void
    }

    struct ButtonDescriber {
        let title: String
        let action: (_ source: Source?, _ profile: UserProfile, _ referencedView: UIView?, _ progress: ProgressHandler) -> Void
        let qualification: (_ source: Source?, _ profile: UserProfile) -> Bool
    }

    // there is no need to call stop animate since the reload is in progress!
    static let buttons: [ButtonDescriber] = [
        //        .init(title: "Edit Profile") { _, _, view, _ in
//            let editor = ProfileEditorController()
//            view?.parentViewController?.present(next: editor)
//        } qualification: { source, profile in
//            source?.user.userId == profile.userId
//        },

        // 三选一
        .init(title: L10n.text("Pending")) { source, profile, referencedView, progress in
            presentConfirmation(message: L10n.text("Cancel follow request?"), onConfim: {
                progress.startAnimate()
                DispatchQueue.global().async {
                    source?.req.requestFollowCancel(userId: profile.userId)
                    UserViewController.reload(userId: profile.userId)
                }
            }, refView: referencedView)
        } qualification: { _, profile in
            profile.hasPendingFollowRequestFromYou
        },
        .init(title: L10n.text("Following"), action: { source, profile, referencedView, progress in
            presentConfirmation(message: L10n.text("Unfollow this user?"), onConfim: {
                progress.startAnimate()
                DispatchQueue.global().async {
                    source?.req.requestFollowDelete(userId: profile.userId)
                    UserViewController.reload(userId: profile.userId)
                }
            }, refView: referencedView)
        }, qualification: { source, profile in
            source?.user.userId != profile.userId &&
                profile.isFollowing
        }),
        .init(title: L10n.text("Follow"), action: { source, profile, _, progress in
            progress.startAnimate()
            DispatchQueue.global().async {
                source?.req.requestFollow(userId: profile.userId)
                UserViewController.reload(userId: profile.userId)
            }
        }, qualification: { source, profile in
            source?.user.userId != profile.userId
                && !profile.isFollowing
                && !profile.hasPendingFollowRequestFromYou
        }),

        .init(title: L10n.text("Accept")) { source, profile, referencedView, progress in
            presentConfirmation(message: L10n.text("Accept this follower?"), onConfim: {
                progress.startAnimate()
                DispatchQueue.global().async {
                    source?.req.requestFollowerApprove(userId: profile.userId)
                    UserViewController.reload(userId: profile.userId)
                }
            }, refView: referencedView)
        } qualification: { _, profile in
            profile.hasPendingFollowRequestToYou
        },
    ]
}

extension UserViewController.ProfileView.ProfileButton {
    class ActionButton: UIView {
        let action: ButtonDescriber
        weak var source: Source?
        weak var profile: UserProfile?

        var progress: ProgressHandler!
        let button = UIButton()
        let indicator = UIActivityIndicatorView()

        init(describingAction action: ButtonDescriber, source: Source, profile: UserProfile) {
            self.action = action
            self.source = source
            self.profile = profile

            super.init(frame: .zero)

            addSubview(button)
            addSubview(indicator)

            progress = .init(startAnimate: { [weak self] in
                self?.button.isHidden = true
                self?.button.isUserInteractionEnabled = false
                self?.indicator.isHidden = false
                self?.indicator.startAnimating()
            }, stopAnimate: { [weak self] in
                self?.button.isHidden = false
                self?.button.isUserInteractionEnabled = true
                self?.indicator.isHidden = true
                self?.indicator.stopAnimating()
            })
            progress.stopAnimate()

            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.titleLabel?.textColor = .systemWhiteAndBlack
            button.titleLabel?.minimumScaleFactor = 0.5
            button.titleLabel?.numberOfLines = 1
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.imageView?.contentMode = .scaleAspectFit

            button.setTitleColor(.systemBlackAndWhite, for: .normal)
            button.tintColor = .systemBlackAndWhite

            button.setTitle(action.title, for: .normal)

            backgroundColor = .separator.withAlphaComponent(0.5)

            button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                    .inset(UIEdgeInsets(horizontal: buttonHorizontalInset, vertical: 0))
            }
            indicator.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = 6 // bounds.height / 2
        }

        @objc func tapped() {
            puddingAnimate()
            guard let source, let profile else { return }
            action.action(source, profile, self, progress)
        }
    }

    class ActionButtonForMore: ActionButton, UIContextMenuInteractionDelegate {
        struct UserMenuAction {
            let title: (_ source: Source, _ profile: UserProfile) -> (String)
            let image: String
            let attributes: UIMenuElement.Attributes
            let action: (_ source: Source, _ profile: UserProfile, _ anchor: UIView) -> Void
            let qualification: (_ source: Source, _ profile: UserProfile) -> Bool

            init(title: String, image: String, attributes: UIMenuElement.Attributes = [], action: @escaping (Source, UserProfile, UIView) -> Void, qualification: @escaping (Source, UserProfile) -> Bool) {
                self.init(
                    title: { _, _ in title },
                    image: image,
                    attributes: attributes,
                    action: action,
                    qualification: qualification
                )
            }

            init(title: @escaping (_ source: Source, _ profile: UserProfile) -> (String), image: String, attributes: UIMenuElement.Attributes = [], action: @escaping (Source, UserProfile, UIView) -> Void, qualification: @escaping (Source, UserProfile) -> Bool) {
                self.title = title
                self.image = image
                self.attributes = attributes
                self.action = action
                self.qualification = qualification
            }
        }

        static let menu: [[UserMenuAction]] = [
            [
                UserMenuAction(title: L10n.text("Refresh"), image: "arrow.clockwise", action: { source, profile, _ in
                    if profile.absoluteUsername.lowercased() == source.user.absoluteUsername.lowercased() {
                        presentMessage(L10n.text("Updating Account Info"))
                        DispatchQueue.global().async {
                            source.populateUserInfo(forceUpdate: true)
                            presentMessage(L10n.text("Account Info Updated"))
                        }
                    } else {
                        UserViewController.reload(userId: profile.userId)
                    }
                }, qualification: { _, _ in true }),
            ],
            [
                UserMenuAction(
                    title: { _, profile in
                        L10n.text("Notes %d", profile.notesCount)
                    }, image: "number", action: { _, profile, _ in
                        presentMessage(L10n.text("You have %d notes", profile.notesCount))
                    }, qualification: { _, _ in true }
                ),
                UserMenuAction(
                    title: { _, profile in
                        L10n.text("Following %d", profile.followingCount)
                    }, image: "person", action: { _, profile, anchor in
                        let controller = FollowingController(userId: profile.userId)
                        anchor.parentViewController?.present(next: controller)
                    }, qualification: { _, _ in true }
                ),
                UserMenuAction(
                    title: { _, profile in
                        L10n.text("Followed By %d", profile.followersCount)
                    }, image: "person", action: { _, profile, anchor in
                        let controller = FollowerController(userId: profile.userId)
                        anchor.parentViewController?.present(next: controller)
                    }, qualification: { _, _ in true }
                ),
            ],
            [
                UserMenuAction(title: L10n.text("Copy Name"), image: "doc.on.doc") { _, profile, _ in
                    UIPasteboard.general.string = profile.name
                    presentMessage(L10n.text("Copied"))
                } qualification: { _, _ in
                    true
                },
                UserMenuAction(title: L10n.text("Copy Username"), image: "doc.on.doc") { _, profile, _ in
                    UIPasteboard.general.string = profile.absoluteUsername
                    presentMessage(L10n.text("Copied"))
                } qualification: { _, _ in
                    true
                },
                UserMenuAction(title: L10n.text("Copy Description"), image: "doc.on.doc") { _, profile, _ in
                    UIPasteboard.general.string = profile.description
                    presentMessage(L10n.text("Copied"))
                } qualification: { _, _ in
                    true
                },
                UserMenuAction(title: L10n.text("Open In Browser"), image: "safari") { source, profile, _ in
                    UIApplication.shared.open(source.host.appendingPathComponent(profile.absoluteUsername))
                } qualification: { _, _ in
                    true
                },
            ],
            [
                UserMenuAction(title: L10n.text("Block"), image: "hand.raised", attributes: [.destructive]) { source, profile, anchor in
                    let name = TextParser().trimToPlainText(from: profile.name)
                    let alert = UIAlertController(title: "⚠️", message: L10n.text("Are you sure you want to block %@?", name), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.text("Block"), style: .destructive, handler: { _ in
                        let progress = UIAlertController(title: "⏳", message: L10n.text("Sending Request"), preferredStyle: .alert)
                        anchor.parentViewController?.present(progress, animated: true)
                        DispatchQueue.global().async {
                            defer { withMainActor {
                                progress.dismiss(animated: true)
                                UserViewController.reload(userId: profile.userId)
                            }}
                            let ret = source.req.requestForBlockUser(userId: profile.userId)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: L10n.text("Cancel"), style: .cancel))
                    anchor.parentViewController?.present(alert, animated: true)
                } qualification: { source, profile in
                    !profile.isBlocking && profile.absoluteUsername.lowercased() != source.user.absoluteUsername.lowercased()
                },
                UserMenuAction(title: L10n.text("Unblock"), image: "lock.slash", attributes: [.destructive]) { source, profile, anchor in
                    let name = TextParser().trimToPlainText(from: profile.name)
                    let alert = UIAlertController(title: "⚠️", message: L10n.text("Are you sure you want to unblock %@?", name), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.text("Unblock"), style: .destructive, handler: { _ in
                        let progress = UIAlertController(title: "⏳", message: L10n.text("Sending Request"), preferredStyle: .alert)
                        anchor.parentViewController?.present(progress, animated: true)
                        DispatchQueue.global().async {
                            defer { withMainActor {
                                progress.dismiss(animated: true)
                                UserViewController.reload(userId: profile.userId)
                            }}
                            let ret = source.req.requestForUnblockUser(userId: profile.userId)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: L10n.text("Cancel"), style: .cancel))
                    anchor.parentViewController?.present(alert, animated: true)
                } qualification: { source, profile in
                    profile.isBlocking && profile.absoluteUsername.lowercased() != source.user.absoluteUsername.lowercased()
                },
                UserMenuAction(title: L10n.text("Remove Follower"), image: "star.slash", attributes: [.destructive]) { source, profile, anchor in
                    let name = TextParser().trimToPlainText(from: profile.name)
                    let alert = UIAlertController(title: "⚠️", message: L10n.text("Are you sure you want to remove %@?", name), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.text("Remove"), style: .destructive, handler: { _ in
                        let progress = UIAlertController(title: "⏳", message: L10n.text("Sending Request"), preferredStyle: .alert)
                        anchor.parentViewController?.present(progress, animated: true)
                        DispatchQueue.global().async {
                            defer { withMainActor {
                                progress.dismiss(animated: true)
                                UserViewController.reload(userId: profile.userId)
                            }}
                            source.req.requestFollowerInvalidate(userId: profile.userId)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: L10n.text("Cancel"), style: .cancel))
                    anchor.parentViewController?.present(alert, animated: true)
                } qualification: { source, profile in
                    profile.isFollowed && profile.absoluteUsername.lowercased() != source.user.absoluteUsername.lowercased()
                },
                UserMenuAction(title: L10n.text("Report"), image: "exclamationmark.bubble", attributes: [.destructive]) { source, profile, anchor in
                    let name = TextParser().trimToPlainText(from: profile.name)
                    let alert = UIAlertController(title: "⚠️", message: L10n.text("Are you sure you want to report %@?", name), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.text("Report"), style: .destructive, handler: { _ in
                        let progress = UIAlertController(title: "⏳", message: L10n.text("Sending Request"), preferredStyle: .alert)
                        anchor.parentViewController?.present(progress, animated: true)
                        DispatchQueue.global().async {
                            defer { withMainActor {
                                progress.dismiss(animated: true)
                                UserViewController.reload(userId: profile.userId)
                            }}
                            source.req.requestReportUser(userId: profile.userId)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: L10n.text("Cancel"), style: .cancel))
                    anchor.parentViewController?.present(alert, animated: true)
                } qualification: { source, profile in
                    profile.absoluteUsername.lowercased() != source.user.absoluteUsername.lowercased()
                },
            ],
        ]

        let previewAnchor = UIView()

        init(source: Source, profile: UserProfile) {
            let desc = ButtonDescriber(title: "...") { _, _, _, _ in } qualification: { _, _ in true }
            super.init(describingAction: desc, source: source, profile: profile)
            button.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
            let interaction = UIContextMenuInteraction(delegate: self)
            button.addInteraction(interaction)
            addSubview(previewAnchor)
            bringSubviewToFront(button)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewAnchor.frame = bounds
        }

        @objc func moreButtonTapped() {
            puddingAnimate()
            button.presentMenu()
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration _: UIContextMenuConfiguration) -> UITargetedPreview? {
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .platformBackground
            parameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 0, height: 0), cornerRadius: 0)
            let preview = UITargetedPreview(view: previewAnchor, parameters: parameters)
            return preview
        }

        func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            guard let source, let profile else { return nil }
            return .init(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: Self.menu.compactMap { menuSection in
                    let actions = menuSection
                        .filter { $0.qualification(source, profile) }
                        .map { desc in
                            UIAction(
                                title: desc.title(source, profile),
                                image: UIImage(systemName: desc.image),
                                attributes: desc.attributes
                            ) { _ in
                                desc.action(source, profile, self)
                            }
                        }
                    guard !actions.isEmpty else { return nil }
                    return UIMenu(options: .displayInline, children: actions)
                })
            }
        }
    }
}
