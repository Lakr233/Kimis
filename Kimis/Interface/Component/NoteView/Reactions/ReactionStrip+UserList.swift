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
        let userCollectionView = UserCollectionView()

        // TODO: Current Api has limit for 100 users, make more!

        init(sourceView: UIView, representReaction: ReactionElement) {
            reactionElement = representReaction
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .popover
            preferredContentSize = CGSize(width: 400, height: 200)
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

            contentView.addSubview(userCollectionView)
            userCollectionView.alpha = 0
            userCollectionView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
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

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
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
                    withUIKitAnimation {
                        self.activityIndicator.alpha = 0
                        self.userCollectionView.alpha = 1
                        self.userCollectionView.userList = userList
                    } completion: {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                    }
                }
            }
        }
    }
}

extension ReactionStrip.UserListPopover {
    class UserCollectionView: UIView {
        let collectionView: UICollectionView
        var userList: [User] = [] {
            didSet { applySnapshot() }
        }

        init() {
            let layout = AlignedCollectionViewFlowLayout(
                horizontalAlignment: .left,
                verticalAlignment: .center
            )
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            collectionView = .init(frame: .zero, collectionViewLayout: layout)
            super.init(frame: .zero)
            addSubview(collectionView)
            collectionView.register(UserCollectionCellView.self, forCellWithReuseIdentifier: String(describing: UserCollectionCellView.self))
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        enum Section { case main }
        typealias DataSource = UICollectionViewDiffableDataSource<Section, User>
        typealias Snapshot = NSDiffableDataSourceSnapshot<Section, User>

        private lazy var dataSource = makeDataSource()
        func makeDataSource() -> DataSource {
            let dataSource = DataSource(
                collectionView: collectionView,
                cellProvider: { collectionView, indexPath, user ->
                    UICollectionViewCell? in
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: String(describing: UserCollectionCellView.self),
                        for: indexPath
                    ) as? UserCollectionCellView
                    cell?.load(user: user)
                    return cell
                }
            )
            return dataSource
        }

        func applySnapshot(animatingDifferences: Bool = true) {
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(userList)
            dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            collectionView.frame = bounds

            let inset = IH.preferredPadding(usingWidth: bounds.width)
            collectionView.contentInset = .init(top: inset, left: inset, bottom: inset, right: inset)
        }
    }

    class UserCollectionCellView: UICollectionViewCell {
        let avatarView = MKImageView()
        let usernameView = TextView.noneInteractive()

        static let cellHeight: CGFloat = 30

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }

        func setup() {
            contentView.addSubview(avatarView)
            contentView.addSubview(usernameView)
            avatarView.snp.makeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.width.height.equalTo(Self.cellHeight)
            }
            usernameView.textAlignment = .left
            usernameView.textContainer.maximumNumberOfLines = 1
            usernameView.textContainer.lineBreakMode = .byTruncatingTail
            usernameView.snp.makeConstraints { make in
                make.left.equalTo(avatarView.snp.right).offset(8)
                make.right.equalToSuperview().inset(8)
                make.width.greaterThanOrEqualTo(Self.cellHeight)
                make.centerY.equalToSuperview()
            }
            contentView.clipsToBounds = true
            contentView.layer.cornerRadius = IH.contentMiniItemCornerRadius
            contentView.backgroundColor = .accent.withAlphaComponent(0.1)
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            avatarView.clear()
            usernameView.text = ""
        }

        func load(user: User) {
            avatarView.loadImage(with: .init(
                url: user.avatarUrl,
                blurHash: user.avatarBlurHash,
                sensitive: false
            ))
            let textParser = TextParser()
            usernameView.attributedText = textParser.compileRenoteUserHeader(with: user)
        }
    }
}
