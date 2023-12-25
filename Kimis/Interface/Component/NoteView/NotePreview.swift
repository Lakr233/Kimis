//
//  NotePreview.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import Source
import UIKit

class NotePreview: UIView {
    // # line 325, reason icon height = text height
    static let hintTextLimit = 1 // <- must be 1
    static let userTextLimit = 2
    static let mainTextLimit = 12
    static let verticalSpacing: CGFloat = 8
    static let defaultAvatarSize: CGFloat = 54
    static let smallerAvatarSize: CGFloat = 30

    var snapshot: Snapshot? {
        didSet {
            if snapshot != oldValue { updateNoteData() }
        }
    }

    var pinned: Bool = false

    let previewReasonIcon = UIImageView()
    let previewReason = TextView(editable: false, selectable: false)
    let avatar = AvatarView()
    let tintIcon = UIImageView()
    let tintIconBackground = UIView()
    let pinnedIcon = UIImageView()
    let avatarButton = UIButton()
    let userText = TextView(editable: false, selectable: false)
    let mainText = TextView(editable: false, selectable: false)
    let pollView = PollView()
    let attachments = NoteAttachmentView()
    let renotePreview = NotePreviewSimple()
    let reactions = ReactionStrip()
    let footerText = TextView(editable: false, selectable: false)
    let operations = NoteOperationStrip()

    init() {
        super.init(frame: .zero)

        previewReason.textContainer.maximumNumberOfLines = Self.hintTextLimit
        userText.textContainer.maximumNumberOfLines = Self.userTextLimit
        mainText.textContainer.maximumNumberOfLines = Self.mainTextLimit

        let views: [UIView] = [
            previewReasonIcon, previewReason,
            avatar, tintIconBackground, tintIcon, pinnedIcon, avatarButton,
            userText, mainText,
            pollView,
            attachments, renotePreview, footerText, reactions, operations,
        ]
        addSubviews(views)

        previewReasonIcon.image = .init(systemName: "lightbulb.fill")?
            .withRenderingMode(.alwaysTemplate)
        previewReasonIcon.contentMode = .scaleAspectFit
        previewReasonIcon.tintColor = .systemGray

        tintIcon.contentMode = .scaleAspectFit
        tintIcon.tintColor = .accent
        tintIconBackground.backgroundColor = .white

        pinnedIcon.image = .fluent(.pin_filled)
        pinnedIcon.contentMode = .scaleAspectFit

        avatarButton.addTarget(self, action: #selector(userAvatarTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let snapshot {
            previewReasonIcon.frame = snapshot.previewReasonIconRect
            previewReasonIcon.isHidden = snapshot.previewReasonIcon == nil
            previewReason.frame = snapshot.previewReasonRect
            previewReason.isHidden = snapshot.previewReasonRect.size.height <= 0
            avatar.frame = snapshot.avatarRect
            tintIcon.frame = snapshot.tintIconRect
            pinnedIcon.frame = snapshot.pinnedIconRect
            avatarButton.frame = snapshot.avatarRect
            userText.frame = snapshot.userTextRect
            mainText.frame = snapshot.mainTextRect
            mainText.isHidden = snapshot.mainTextRect.size.height <= 0
            pollView.frame = snapshot.pollViewRect
            pollView.isHidden = snapshot.pollViewRect.size.height <= 0
            attachments.frame = snapshot.attachmentsRect
            attachments.isHidden = snapshot.attachmentsRect.size.height <= 0
            renotePreview.frame = snapshot.renotePreviewRect
            renotePreview.isHidden = snapshot.renotePreviewRect.size.height <= 0
            reactions.frame = snapshot.reactionsRect
            reactions.isHidden = snapshot.reactionsRect.size.height <= 0
            footerText.frame = snapshot.footerTextRect
            operations.frame = snapshot.operationsRect
            operations.isHidden = snapshot.operationsRect.height <= 0
        } else {
            previewReasonIcon.frame = .zero
            previewReason.frame = .zero
            avatar.frame = .zero
            tintIcon.frame = .zero
            pinnedIcon.frame = .zero
            avatarButton.frame = .zero
            userText.frame = .zero
            mainText.frame = .zero
            pollView.frame = .zero
            attachments.frame = .zero
            renotePreview.frame = .zero
            reactions.frame = .zero
            footerText.frame = .zero
            operations.frame = .zero
        }
        tintIconBackground.frame = tintIcon.frame.inset(by: .init(inset: 2))
        tintIconBackground.layer.cornerRadius = tintIconBackground.frame.width / 2
        renotePreview.snapshot = snapshot?.renoteSnapshot
        attachments.snapshot = snapshot?.attachmentSnapshot
        reactions.snapshot = snapshot?.reactionSnapshot
        for view in subviews { view.layoutSubviews() }
    }

    func clear() {
        avatar.clear()
        pinnedIcon.isHidden = true
        previewReasonIcon.image = nil
        previewReason.attributedText = .init()
        userText.attributedText = .init()
        mainText.attributedText = .init()
        pollView.snapshot = nil
        attachments.snapshot = nil
        renotePreview.snapshot = nil
        reactions.snapshot = nil
        operations.noteId = nil
        tintIcon.image = nil
        tintIcon.isHidden = true
    }

    func updateNoteData() {
        guard let snapshot else {
            clear()
            return
        }
        avatar.loadImage(with: .init(url: snapshot.user.avatarUrl, blurHash: snapshot.user.avatarBlurHash))
        previewReasonIcon.image = snapshot.previewReasonIcon
        previewReason.attributedText = snapshot.previewReasonText
        mainText.attributedText = snapshot.mainText
        userText.attributedText = snapshot.userText
        pollView.snapshot = snapshot.voteSnapshot
        attachments.snapshot = snapshot.attachmentSnapshot
        renotePreview.snapshot = snapshot.renoteSnapshot
        reactions.snapshot = snapshot.reactionSnapshot
        footerText.attributedText = snapshot.footerText
        operations.noteId = snapshot.note.noteId

        pinnedIcon.isHidden = !pinned

        if snapshot.note.replyId != nil {
            tintIcon.image = UIImage(systemName: "arrowshape.turn.up.left.circle.fill")
            tintIcon.isHidden = false
        } else if snapshot.note.renoteId != nil {
            tintIcon.image = UIImage(systemName: "arrowshape.turn.up.right.circle.fill")
            tintIcon.isHidden = false
        } else {
            tintIcon.isHidden = true
        }
        tintIconBackground.isHidden = tintIcon.isHidden

        setNeedsLayout()
    }

    @objc func userAvatarTapped() {
        if let userId = snapshot?.user.userId {
            ControllerRouting.pushing(tag: .user, referencer: self, associatedData: userId)
        } else {
            assertionFailure()
        }
    }
}

extension NotePreview {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var note: Note = .missingDataHolder
        var user: User = .unavailable

        var previewReasonIconRect: CGRect = .zero
        var previewReasonIcon: UIImage?
        var previewReasonRect: CGRect = .zero
        var previewReasonText: NSMutableAttributedString = .init()
        var avatarRect: CGRect = .zero
        var tintIconRect: CGRect = .zero
        var pinnedIconRect: CGRect = .zero
        var userTextRect: CGRect = .zero
        var userText: NSMutableAttributedString = .init()
        var mainTextRect: CGRect = .zero
        var mainText: NSMutableAttributedString = .init()
        var pollViewRect: CGRect = .zero
        var attachmentsRect: CGRect = .zero
        var renotePreviewRect: CGRect = .zero
        var reactionsRect: CGRect = .zero
        var footerTextRect: CGRect = .zero
        var footerText: NSMutableAttributedString = .init()
        var operationsRect: CGRect = .zero

        var voteSnapshot: PollView.Snapshot?
        var renoteSnapshot: NotePreviewSimple.Snapshot?
        var attachmentSnapshot: NoteAttachmentView.Snapshot?
        var reactionSnapshot: ReactionStrip.Snapshot?

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(note)
            hasher.combine(user)
            hasher.combine(previewReasonIconRect)
            hasher.combine(previewReasonIcon)
            hasher.combine(previewReasonRect)
            hasher.combine(previewReasonText)
            hasher.combine(avatarRect)
            hasher.combine(tintIconRect)
            hasher.combine(pinnedIconRect)
            hasher.combine(userTextRect)
            hasher.combine(userText)
            hasher.combine(mainTextRect)
            hasher.combine(mainText)
            hasher.combine(pollViewRect)
            hasher.combine(attachmentsRect)
            hasher.combine(renotePreviewRect)
            hasher.combine(reactionsRect)
            hasher.combine(footerTextRect)
            hasher.combine(footerText)
            hasher.combine(operationsRect)
            hasher.combine(voteSnapshot)
            hasher.combine(renoteSnapshot)
            hasher.combine(attachmentSnapshot)
            hasher.combine(reactionSnapshot)
        }
    }
}

extension NotePreview.Snapshot {
    struct RenderHint {
        let avatarSize: CGFloat
        weak var context: NoteCell.Context?
    }

    convenience init(usingWidth width: CGFloat, context: NoteCell.Context) {
        let avatarSize = IH.preferredAvatarSizeOffset(usingWidth: width) + NotePreview.defaultAvatarSize
        self.init(usingWidth: width, avatarSize: avatarSize, context: context)
    }

    convenience init(usingWidth width: CGFloat, avatarSize: CGFloat, context: NoteCell.Context) {
        self.init()
        render(usingWidth: width, avatarSize: avatarSize, context: context)
    }

    func render(usingWidth width: CGFloat, avatarSize: CGFloat, context: NoteCell.Context) {
        renderHint = RenderHint(avatarSize: avatarSize, context: context)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }

        guard let context = hint.context else { return }
        let verticalSpacing = NotePreview.verticalSpacing
        let horizontalSpacing = verticalSpacing

        let avatarSize = hint.avatarSize
        let contentLeftAlign = avatarSize + horizontalSpacing
        let contentWidth = width - contentLeftAlign - horizontalSpacing

        let textParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = true
            parser.paragraphStyle.lineSpacing = IH.preferredParagraphStyleLineSpacing
            parser.paragraphStyle.paragraphSpacing = 0
            return parser
        }()

        var note = context.source?.notes.retain(context.noteId) ?? .missingDataHolder
        var user = context.source?.users.retain(note.userId) ?? User()

        var previewReasonIcon: UIImage?
        var previewReasonText = NSMutableAttributedString()

        if context.disablePreviewReason {
            // pass!
        } else if !context.disableRenoteOptomization, let renote = note.renoteId, note.justRenote {
            previewReasonText = textParser.compilePreviewReasonForRenote(withUser: user)
            previewReasonIcon = .fluent(.arrow_reply_filled)

            note = context.source?.notes.retain(renote) ?? .missingDataHolder
            user = context.source?.users.retain(note.userId) ?? User()
        } else if let instanceName = textParser.compilePreviewReasonForInstanceName(withUser: user) {
            previewReasonText = instanceName
            previewReasonIcon = .fluent(.cloud_swap_filled)
        }

        var previewResaonRect: CGRect = .zero
        let previewReasonHeight = previewReasonText
            .measureHeight(usingWidth: contentWidth, lineLimit: NotePreview.hintTextLimit)
        previewResaonRect = .init(
            x: contentLeftAlign,
            y: 0,
            width: contentWidth,
            height: previewReasonHeight > 0 ? previewReasonHeight : -verticalSpacing
        )
        let previewReasonIconSize = max(0, previewResaonRect.size.height)
        let previewReasonIconRect = CGRect(
            x: contentLeftAlign - horizontalSpacing - previewReasonIconSize,
            y: previewResaonRect.origin.y,
            width: previewReasonIconSize,
            height: previewReasonIconSize
        )

        let avatarRect = CGRect(
            x: 0,
            y: previewResaonRect.origin.y + previewResaonRect.size.height + verticalSpacing,
            width: avatarSize,
            height: avatarSize
        )

        let tintIconSize: CGFloat = avatarSize / 3
        let tintIconRect = CGRect(
            x: avatarRect.maxX - tintIconSize,
            y: avatarRect.maxY - tintIconSize,
            width: tintIconSize,
            height: tintIconSize
        )

        let pinnedIconRect = CGRect(
            x: avatarRect.maxX - tintIconSize,
            y: avatarRect.minY,
            width: tintIconSize,
            height: tintIconSize
        )

        let userText = textParser.compileUserHeader(with: user, lineBreak: false)
        let userTextHeight = userText
            .measureHeight(usingWidth: contentWidth, lineLimit: NotePreview.userTextLimit)
        let userTextRect = CGRect(
            x: contentLeftAlign,
            y: avatarRect.minY,
            width: contentWidth,
            height: userTextHeight
        )

        let mainText = textParser.compileNoteBody(withNote: note)
        let mainTextHeight = mainText
            .measureHeight(usingWidth: contentWidth, lineLimit: NotePreview.mainTextLimit)
        let mainTextViewRect = CGRect(
            x: contentLeftAlign,
            y: userTextRect.maxY + verticalSpacing,
            width: contentWidth,
            height: mainTextHeight > 0 ? mainTextHeight : -verticalSpacing
        )

        var voteSnapshot: PollView.Snapshot?
        let pollViewRect: CGRect
        if let vote = note.poll {
            let snapshot = PollView.Snapshot(
                usingWidth: contentWidth,
                textParser: textParser,
                poll: vote,
                noteId: note.noteId,
                spacing: verticalSpacing
            )
            voteSnapshot = snapshot
            pollViewRect = CGRect(
                x: contentLeftAlign,
                y: mainTextViewRect.origin.y + mainTextViewRect.size.height + verticalSpacing,
                width: contentWidth,
                height: snapshot.height > 0 ? snapshot.height : -verticalSpacing
            )
        } else {
            pollViewRect = CGRect(
                x: contentLeftAlign,
                y: mainTextViewRect.origin.y + mainTextViewRect.size.height + verticalSpacing,
                width: contentWidth,
                height: -verticalSpacing
            )
        }

        let attachmentElements = NoteCell.Context.createAttachmentElements(withNote: note)
        let attachmentSnapshot = NoteAttachmentView.Snapshot(usingWidth: contentWidth, elements: attachmentElements, limit: 4)
        let attachmentHeight: CGFloat = attachmentSnapshot.height
        let attachmentRect = CGRect(
            x: contentLeftAlign,
            y: pollViewRect.origin.y + pollViewRect.size.height + verticalSpacing,
            width: contentWidth,
            height: attachmentHeight > 0 ? attachmentHeight : -verticalSpacing
        )

        let renoteSnapshot = NotePreviewSimple.Snapshot(usingWidth: contentWidth, target: note.renoteId, context: context, textParser: textParser)
        let renoteHeight: CGFloat = renoteSnapshot.height
        let renoteRect = CGRect(
            x: contentLeftAlign,
            y: attachmentRect.origin.y + attachmentRect.size.height + verticalSpacing,
            width: contentWidth,
            height: renoteHeight > 0 ? renoteHeight : -verticalSpacing
        )

        let footerText = textParser.compileNoteFooter(withNote: note)
        let footerTextSize = footerText
            .measureHeight(usingWidth: contentWidth)
        let footerTextRect = CGRect(
            x: contentLeftAlign,
            y: renoteRect.origin.y + renoteRect.size.height + verticalSpacing,
            width: contentWidth,
            height: footerTextSize
        )

        let reactionElements = NoteCell.Context.createReactionStripElemetns(withNote: note, source: context.source)
        let reactionSnapshot = ReactionStrip.Snapshot(usingWidth: contentWidth, viewElements: reactionElements, limitation: 32)
        let reactionHeight: CGFloat = reactionSnapshot.height
        let reactionRect = CGRect(
            x: contentLeftAlign,
            y: footerTextRect.maxY + verticalSpacing,
            width: contentWidth,
            height: reactionHeight > 0 ? reactionHeight : -verticalSpacing
        )

        let operationRect: CGRect
        if context.disableOperationStrip {
            operationRect = CGRect(
                x: contentLeftAlign,
                y: reactionRect.origin.y + reactionRect.size.height,
                width: contentWidth,
                height: 0
            )
        } else {
            operationRect = CGRect(
                x: contentLeftAlign,
                y: reactionRect.origin.y + reactionRect.size.height + verticalSpacing,
                width: contentWidth,
                height: NoteOperationStrip.contentHeight
            )
        }

        height = operationRect.maxY
        self.note = note
        self.user = user
        self.previewReasonIconRect = previewReasonIconRect
        self.previewReasonIcon = previewReasonIcon
        previewReasonRect = previewResaonRect
        self.previewReasonText = previewReasonText
        self.avatarRect = avatarRect
        self.tintIconRect = tintIconRect
        self.pinnedIconRect = pinnedIconRect
        self.userTextRect = userTextRect
        self.userText = userText
        mainTextRect = mainTextViewRect
        self.mainText = mainText
        self.pollViewRect = pollViewRect
        attachmentsRect = attachmentRect
        renotePreviewRect = renoteRect
        reactionsRect = reactionRect
        self.footerTextRect = footerTextRect
        self.footerText = footerText
        operationsRect = operationRect
        self.voteSnapshot = voteSnapshot
        self.renoteSnapshot = renoteSnapshot
        self.attachmentSnapshot = attachmentSnapshot
        self.reactionSnapshot = reactionSnapshot
    }

    func invalidate() {
        width = 0
        height = 0
        note = .missingDataHolder
        user = .unavailable
        previewReasonIconRect = .zero
        previewReasonIcon = nil
        previewReasonRect = .zero
        previewReasonText = .init()
        avatarRect = .zero
        tintIconRect = .zero
        pinnedIconRect = .zero
        userTextRect = .zero
        userText = .init()
        mainTextRect = .zero
        mainText = .init()
        pollViewRect = .zero
        attachmentsRect = .zero
        renotePreviewRect = .zero
        reactionsRect = .zero
        footerTextRect = .zero
        footerText = .init()
        operationsRect = .zero
        voteSnapshot = nil
        renoteSnapshot = nil
        attachmentSnapshot = nil
        reactionSnapshot = nil
    }
}
