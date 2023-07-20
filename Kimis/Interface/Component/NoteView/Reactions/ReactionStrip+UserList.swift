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
    class UserCollectionView: UIView, UICollectionViewDelegate {
        let collectionView: UICollectionView
        let layout = AlignedCollectionViewFlowLayout(
            horizontalAlignment: .left,
            verticalAlignment: .center
        )
        var userList: [User] = [] {
            didSet { applySnapshot() }
        }

        static let inset: CGFloat = 4
        let cellHeight: CGFloat = NSAttributedString(string: "M\nM", attributes: [
            .font: UIFont.systemFont(ofSize: CGFloat(AppConfig.current.defaultNoteFontSize)),
        ])
        .measureHeight(usingWidth: 100, lineLimit: 2, lineBreakMode: .byWordWrapping)
        + inset

        var contentWidth: CGFloat {
            collectionView.frame.width
                - collectionView.contentInset.left
                - collectionView.contentInset.right
        }

        var cellSize: CGSize {
            .init(width: contentWidth, height: cellHeight)
        }

        init() {
            collectionView = .init(frame: .zero, collectionViewLayout: layout)
            super.init(frame: .zero)
            addSubview(collectionView)
//            collectionView.register(SimpleSectionHeader.self, forCellWithReuseIdentifier: SimpleSectionHeader.headerId)
            collectionView.register(UserCollectionCellView.self, forCellWithReuseIdentifier: String(describing: UserCollectionCellView.self))
            collectionView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            collectionView.delegate = self
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

        var prevWidth: CGFloat = 0
        override func layoutSubviews() {
            super.layoutSubviews()
            collectionView.frame = bounds
            if prevWidth != collectionView.frame.width {
                withUIKitAnimation {
                    self.layout.estimatedItemSize = self.cellSize
                    self.layout.itemSize = self.cellSize
                    self.collectionView.performBatchUpdates(nil, completion: nil)
                    self.collectionView.layoutIfNeeded()
                }
            }
        }
    }

    class UserCollectionCellView: UICollectionViewCell {
        let insetView = UIView()
        let avatarView = AvatarView()
        let usernameView = TextView.noneInteractive()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }

        static let inset: CGFloat = 4

        func setup() {
            contentView.addSubview(insetView)
            insetView.addSubview(avatarView)
            insetView.addSubview(usernameView)
            usernameView.textAlignment = .left
            usernameView.textContainer.maximumNumberOfLines = 2
            usernameView.textContainer.lineBreakMode = .byTruncatingTail
            insetView.clipsToBounds = true
            insetView.layer.cornerRadius = IH.contentMiniItemCornerRadius
//            let thatColor = UIColor.accent.withAlphaComponent(0.1)
//            insetView.backgroundColor = thatColor
//            insetView.layer.borderColor = thatColor.cgColor
//            insetView.layer.borderWidth = 1
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            avatarView.clear()
            usernameView.text = ""
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            insetView.frame = contentView.bounds.inset(by: .init(
                top: Self.inset, left: Self.inset, bottom: Self.inset, right: Self.inset
            ))
            avatarView.frame = .init(
                x: 0,
                y: 0,
                width: insetView.bounds.height,
                height: insetView.bounds.height
            )
            let nameContainerWidth = insetView.bounds.width - avatarView.frame.width - Self.inset * 3
            let textHeight = usernameView.attributedText.measureHeight(
                usingWidth: nameContainerWidth,
                lineLimit: usernameView.textContainer.maximumNumberOfLines,
                lineBreakMode: usernameView.textContainer.lineBreakMode
            )
            if textHeight > 0 {
                usernameView.frame = .init(
                    x: avatarView.frame.width + Self.inset * 2,
                    y: (insetView.bounds.height - textHeight) / 2,
                    width: nameContainerWidth,
                    height: textHeight
                )
            } else {
                usernameView.frame = .init(
                    x: avatarView.frame.width + Self.inset * 2,
                    y: 0,
                    width: nameContainerWidth,
                    height: insetView.bounds.height
                )
            }
        }

        func load(user: User) {
            avatarView.loadImage(with: .init(
                url: user.avatarUrl,
                blurHash: user.avatarBlurHash,
                sensitive: false
            ))
            let textParser = TextParser()
            usernameView.attributedText = textParser.compileRenoteUserHeader(with: user, lineBreak: true)
        }

        func setWidth(_ width: CGFloat) {
            insetView.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }

//    class SimpleSectionHeader: UICollectionReusableView {
//        let label = UILabel()
//        let effect: UIView
//
//        static let headerId = "wiki.qaq.SimpleSectionHeader"
//
//        override init(frame: CGRect) {
//            let blur = UIBlurEffect(style: .regular)
//            let effect = UIVisualEffectView(effect: blur)
//            self.effect = effect
//
//            label.textAlignment = .left
//            label.font = .systemFont(ofSize: 12, weight: .semibold)
//            label.alpha = 0.5
//
//            super.init(frame: frame)
//
//            addSubview(effect)
//            addSubview(label)
//        }
//
//        override func layoutSubviews() {
//            super.layoutSubviews()
//            label.frame = bounds.inset(by: UIEdgeInsets(horizontal: 4, vertical: 0))
//            effect.frame = bounds.inset(by: UIEdgeInsets(horizontal: -50, vertical: 0))
//        }
//
//        @available(*, unavailable)
//        required init?(coder _: NSCoder) {
//            fatalError()
//        }
//
//        override func prepareForReuse() {
//            label.text = ""
//        }
//    }
}
