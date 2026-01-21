//
//  UserPreview.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import Source
import UIKit

class UserPreview: UIView {
    static let usernameTextViewLimit = 2
    static let userDescTextViewLimit = 4
    static let defaultAvatarSize: CGFloat = 36

    let avatarView = MKRoundedImageView()
    let usernameTextView = TextView.noneInteractive()

    var snapshot: Snapshot? {
        didSet { updateDataSource() }
    }

    init() {
        super.init(frame: .zero)

        addSubview(avatarView)
        addSubview(usernameTextView)

        usernameTextView.textContainer.maximumNumberOfLines = Self.usernameTextViewLimit
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let snapshot {
            avatarView.frame = snapshot.avatarFrame
            usernameTextView.frame = snapshot.usernameFrame
        } else {
            avatarView.frame = .zero
            usernameTextView.frame = .zero
        }
    }

    func prepareForReuse() {
        avatarView.loadImage(with: nil)
        usernameTextView.attributedText = nil
    }

    func updateDataSource() {
        guard let snapshot else {
            prepareForReuse()
            return
        }
        avatarView.loadImage(with: .init(
            url: snapshot.user.avatarUrl,
            blurHash: snapshot.user.avatarBlurhash,
        ))
        usernameTextView.attributedText = snapshot.username

        setNeedsLayout()
    }
}

extension UserPreview {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var user: UserProfile = .init()

        var width: CGFloat = 0
        var height: CGFloat = 0

        var avatarFrame: CGRect = .zero
        var usernameFrame: CGRect = .zero

        var username: NSMutableAttributedString = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(user)
            hasher.combine(height)
            hasher.combine(avatarFrame)
            hasher.combine(usernameFrame)
            hasher.combine(username)
        }
    }
}

extension UserPreview.Snapshot {
    convenience init(usingWidth width: CGFloat, user: UserProfile) {
        self.init()
        render(usingWidth: width, user: user)
    }

    func render(usingWidth width: CGFloat, user: UserProfile) {
        renderHint = user
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let user = renderHint as? UserProfile else {
            assertionFailure()
            return
        }

        let spacing: CGFloat = IH.preferredParagraphStyleLineSpacing

        let textParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = true
            parser.paragraphStyle.lineSpacing = spacing
            parser.paragraphStyle.paragraphSpacing = 0
            return parser
        }()

        let padding = IH.preferredPadding(usingWidth: width)

        let usernameText = textParser.compileUserHeader(with: User.converting(user), lineBreak: false)

        let avatarSize = UserPreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)
        let avatarFrame = CGRect(
            x: 0, // paddings on the x-axis are handled in UserCell.swift
            y: padding,
            width: avatarSize,
            height: avatarSize,
        )
        let contentAlign = avatarFrame.maxX + padding
        let contentWidth = width - contentAlign

        let nameHeight = usernameText
            .measureHeight(usingWidth: contentWidth, lineLimit: UserPreview.usernameTextViewLimit)
        let usernameTextFrame = CGRect(
            x: contentAlign,
            y: avatarFrame.minY,
            width: contentWidth,
            height: nameHeight,
        )

        let height = max(avatarFrame.maxY, usernameTextFrame.maxY) + padding

        self.width = width
        self.user = user
        self.height = height
        self.avatarFrame = avatarFrame
        usernameFrame = usernameTextFrame
        username = usernameText
    }

    func invalidate() {
        user = .init()
        width = 0
        height = 0
        avatarFrame = .zero
        usernameFrame = .zero
        username = .init()
    }
}
