//
//  NotificationCell+Main.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

extension NotificationCell {
    class MainCell: NotificationCell {
        static let titleLineLimit: Int = 2
        static let descriptionLineLimit: Int = 12

        let actionView = UIImageView()
        let reactionLabel = UILabel()
        let reactionImageView = MKImageView()
        let unreadTintView = UIView()
        let avatarView = AvatarView()
        let avatarButton = UIButton()
        let titleTextView = TextView(editable: false, selectable: false, disableLink: false)
        let mainTextView = TextView(editable: false, selectable: false, disableLink: false)
        let footerTextView = TextView(editable: false, selectable: false, disableLink: false)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            actionView.contentMode = .scaleAspectFit
            actionView.tintColor = .accent
            reactionLabel.font = .systemFont(ofSize: 64)
            reactionLabel.numberOfLines = 1
            reactionLabel.minimumScaleFactor = 0.001
            reactionLabel.adjustsFontSizeToFitWidth = true
            reactionLabel.textAlignment = .center
            reactionImageView.contentMode = .scaleAspectFit
            reactionImageView.layer.cornerRadius = 2

            actionView.isHidden = true
            reactionLabel.isHidden = true
            reactionImageView.isHidden = true

            titleTextView.textContainer.maximumNumberOfLines = Self.titleLineLimit
            mainTextView.textContainer.maximumNumberOfLines = Self.descriptionLineLimit

            avatarButton.addTarget(self, action: #selector(avatarButtonTapped), for: .touchUpInside)

            unreadTintView.backgroundColor = .systemPink

            let views: [UIView] = [
                actionView, reactionImageView, reactionLabel,
                avatarView, avatarButton, titleTextView,
                mainTextView, footerTextView,
                unreadTintView,
            ]
            container.addSubviews(views)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let get = context?.snapshot, let snapshot = get as? Snapshot {
                actionView.frame = snapshot.actionViewRect
                reactionImageView.frame = actionView.frame
                reactionLabel.frame = actionView.frame
                avatarView.frame = snapshot.avatarViewRect
                avatarButton.frame = avatarView.frame
                titleTextView.frame = snapshot.titleTextViewRect
                mainTextView.frame = snapshot.mainTextViewRect
                footerTextView.frame = snapshot.footerTextViewRect
                unreadTintView.frame = snapshot.unreadTintViewRect
            } else {
                assert(context?.snapshot == nil)
                actionView.frame = .zero
                avatarView.frame = .zero
                avatarButton.frame = .zero
                titleTextView.frame = .zero
                mainTextView.frame = .zero
            }

            unreadTintView.layer.cornerRadius = unreadTintView.frame.width / 2
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            unreadTintView.isHidden = true
            actionView.image = nil
            reactionLabel.text = ""
            reactionImageView.loadImage(with: nil)
            avatarView.loadImage(with: nil)
            titleTextView.attributedText = nil
            mainTextView.attributedText = nil
            footerTextView.attributedText = nil
            actionView.isHidden = true
            reactionLabel.isHidden = true
            reactionImageView.isHidden = true
        }

        override func load(_ context: NotificationCell.Context) {
            super.load(context)

            unreadTintView.isHidden = context.read

            if let snapshot = context.snapshot as? Snapshot {
                avatarView.loadImage(with: snapshot.avatarImage)
                titleTextView.attributedText = snapshot.titleText
                mainTextView.attributedText = snapshot.mainText
                footerTextView.attributedText = snapshot.footerText

                if let reaction = context.notification?.reaction {
                    if reaction.hasPrefix(":"), reaction.hasSuffix(":") {
                        let name = String(reaction.dropFirst().dropLast())
                        if let url = source?.host
                            .appendingPathComponent("emoji")
                            .appendingPathComponent(name)
                            .appendingPathExtension("webp")
                        {
                            reactionImageView.loadImage(with: .init(url: url))
                            reactionImageView.isHidden = false
                        }
                    } else {
                        reactionLabel.text = reaction
                        reactionLabel.isHidden = false
                    }
                } else {
                    assert(snapshot.actionImage != nil)
                    actionView.image = snapshot.actionImage
                    actionView.isHidden = false
                }
            }
        }

        @objc func avatarButtonTapped() {
            avatarView.puddingAnimate()
            if let userId = context?.notification?.userId {
                ControllerRouting.pushing(tag: .user, referencer: self, associatedData: userId)
            }
        }
    }
}

extension NotificationCell.MainCell {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var actionImage: UIImage?
        var actionViewRect: CGRect = .zero
        var avatarImage: MKImageView.Request?
        var avatarViewRect: CGRect = .zero
        var titleText: NSMutableAttributedString = .init()
        var titleTextViewRect: CGRect = .zero
        var mainText: NSMutableAttributedString = .init()
        var mainTextViewRect: CGRect = .zero
        var footerText: NSMutableAttributedString = .init()
        var footerTextViewRect: CGRect = .zero
        var unreadTintViewRect: CGRect = .zero

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(actionImage)
            hasher.combine(actionViewRect)
            hasher.combine(avatarImage)
            hasher.combine(avatarViewRect)
            hasher.combine(titleText)
            hasher.combine(titleTextViewRect)
            hasher.combine(mainText)
            hasher.combine(mainTextViewRect)
            hasher.combine(footerText)
            hasher.combine(footerTextViewRect)
            hasher.combine(unreadTintViewRect)
        }
    }
}

extension NotificationCell.MainCell.Snapshot {
    struct RenderHint {
        let notification: RemoteNotification
        weak var source: Source?
    }

    convenience init(usingWidth width: CGFloat, rendering notification: RemoteNotification, source: Source?) {
        self.init()
        render(usingWidth: width, rendering: notification, source: source)
    }

    func render(usingWidth width: CGFloat, rendering notification: RemoteNotification?, source: Source?) {
        guard let source, let notification else {
            return
        }
        renderHint = RenderHint(notification: notification, source: source)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }

        guard let source = hint.source else {
            return
        }
        let notification = hint.notification

        let padding = IH.preferredPadding(usingWidth: width)
        let tintSize = CGSize(width: 24, height: 24)
        let avatarR = NotePreview.defaultAvatarSize + IH.preferredAvatarSizeOffset(usingWidth: width)
        let avatarSize = CGSize(width: avatarR, height: avatarR)
        let horizontalSpacing: CGFloat = 8
        let verticalSpacing: CGFloat = 8

        let textParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = true
            parser.paragraphStyle.lineSpacing = IH.preferredParagraphStyleLineSpacing
            parser.paragraphStyle.paragraphSpacing = 2
            return parser
        }()

        let actionImage = notification.type.tintIcon
        let actionImageRect = CGRect(
            x: padding,
            y: padding,
            width: tintSize.width,
            height: tintSize.height,
        )

        let contentAlignment = actionImageRect.maxX + horizontalSpacing
        let contentWidth = width - padding - contentAlignment
        var contentStart: CGFloat = padding

        var avatarImage: MKImageView.Request?
        var avatarViewRect: CGRect = .zero
        var titleText: NSMutableAttributedString = .init()
        var titleViewRect: CGRect = .zero
        let user = source.users.retain(notification.userId)
            ?? source.users.retain(source.notes.retain(notification.noteId)?.userId)
            ?? .unavailable
        avatarImage = MKImageView.Request(
            url: user.avatarUrl,
            blurHash: user.avatarBlurHash,
            sensitive: false,
        )
        avatarViewRect = CGRect(
            x: contentAlignment,
            y: actionImageRect.minX,
            width: avatarSize.width,
            height: avatarSize.height,
        )
        let titleWidth = contentWidth - avatarViewRect.width - horizontalSpacing

        titleText = textParser.compileUserHeader(with: user, lineBreak: true)
        var titleHeight: CGFloat = 0
        titleHeight = titleText.measureHeight(
            usingWidth: titleWidth,
            lineLimit: NotificationCell.MainCell.titleLineLimit,
        )

        if titleHeight > avatarViewRect.height {
            titleViewRect = CGRect(
                x: avatarViewRect.maxX + horizontalSpacing,
                y: avatarViewRect.minY,
                width: titleWidth,
                height: titleHeight,
            )
            avatarViewRect = CGRect(
                x: avatarViewRect.minX,
                y: avatarViewRect.minY + (titleViewRect.height - avatarViewRect.height) / 2,
                width: avatarViewRect.size.width,
                height: avatarViewRect.size.height,
            )
        } else {
            titleViewRect = CGRect(
                x: avatarViewRect.maxX + horizontalSpacing,
                y: avatarViewRect.midY - titleHeight / 2,
                width: titleWidth,
                height: titleHeight,
            )
        }
        contentStart = max(avatarViewRect.maxY, titleViewRect.maxY) + verticalSpacing

        var noteBody: [NSMutableAttributedString] = []
        if let note = source.notes.retain(notification.noteId) {
            let body = textParser.compileNoteBody(withNote: note, removeDuplicatedNewLines: true)
            noteBody.append(body)

            let attachmentCount = note.attachments.count
            if attachmentCount > 0 { noteBody.append(.init(string: "📎x\(attachmentCount)")) }
            if note.text.isEmpty,
               let renoteId = note.renoteId,
               let renote = source.notes.retain(renoteId)
            {
                let body = textParser.compileNoteBody(withNote: renote, removeDuplicatedNewLines: true)
                noteBody.append(body)
            }
        }
        let notePreflight = textParser.connect(strings: noteBody, separator: " ")
        let noteDescription = textParser.finalize(notePreflight)

        let mainText = textParser.finalize(textParser.connect(strings: [
            NSMutableAttributedString(string: notification.type.title),
            noteDescription,
        ], separator: "\n"))
        let mainTextHeigh = mainText
            .measureHeight(usingWidth: contentWidth, lineLimit: NotificationCell.MainCell.descriptionLineLimit)
        let mainTextRect = CGRect(
            x: contentAlignment,
            y: contentStart,
            width: contentWidth,
            height: mainTextHeigh,
        )

        let footerText = textParser.compileDateFooter(withDate: notification.createdAt)
        let footerTextHeight = footerText
            .measureHeight(usingWidth: contentWidth)
        let footerTextRect = CGRect(
            x: contentAlignment,
            y: mainTextRect.maxY + verticalSpacing,
            width: contentWidth,
            height: footerTextHeight,
        )

        let unreadSize: CGFloat = 12
        let unreadTintViewRect = CGRect(
            x: actionImageRect.center.x - unreadSize / 2,
            y: actionImageRect.maxY + verticalSpacing,
            width: unreadSize,
            height: unreadSize,
        )

        let cellHeight = max(footerTextRect.maxY, actionImageRect.maxY) + padding

        self.width = width
        height = cellHeight
        self.actionImage = actionImage
        actionViewRect = actionImageRect
        self.avatarImage = avatarImage
        self.avatarViewRect = avatarViewRect
        self.titleText = titleText
        titleTextViewRect = titleViewRect
        self.mainText = mainText
        mainTextViewRect = mainTextRect
        self.footerText = footerText
        footerTextViewRect = footerTextRect
        self.unreadTintViewRect = unreadTintViewRect
    }

    func invalidate() {
        width = 0
        height = 0
        actionImage = nil
        actionViewRect = .zero
        avatarImage = nil
        avatarViewRect = .zero
        titleText = .init()
        titleTextViewRect = .zero
        mainText = .init()
        mainTextViewRect = .zero
        footerText = .init()
        footerTextViewRect = .zero
        unreadTintViewRect = .zero
    }
}
