//
//  NoteCell+NoteView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import Source
import UIKit

class NoteView: UIView {
    static let verticalSpacing: CGFloat = 8
    static let defaultAvatarSize: CGFloat = 54
    static let smallerAvatarSize: CGFloat = 30

    var snapshot: Snapshot? {
        didSet {
            if snapshot != oldValue { updateNoteData() }
        }
    }

    let avatar = AvatarView()
    let tintIcon = UIImageView()
    let tintIconBackground = UIView()
    let avatarButton = UIButton()
    let userHeaderText = TextView(editable: false, selectable: true)
    let mainText = TextView(editable: false, selectable: true)
    let pollView = PollView()
    let attachments = NoteAttachmentView()
    let renotePreview = NotePreviewSimple()
    let reactions = ReactionStrip()
    let footerText = TextView(editable: false, selectable: true)
    let operationSeparatorUp = UIView()
    let operations = NoteOperationStrip()
    let operationSeparatorDown = UIView()

    init() {
        super.init(frame: .zero)

        let views: [UIView] = [
            avatar, tintIconBackground, tintIcon, avatarButton, userHeaderText,
            mainText, pollView, attachments, renotePreview, footerText,
            reactions,
            operationSeparatorUp, operations, operationSeparatorDown,
        ]
        addSubviews(views)

        tintIcon.contentMode = .scaleAspectFit
        tintIcon.tintColor = .accent
        tintIconBackground.backgroundColor = .white

        operationSeparatorUp.backgroundColor = .separator
        operationSeparatorDown.backgroundColor = .separator
        operationSeparatorUp.alpha = 0.5
        operationSeparatorDown.alpha = 0.5

        operations.maxWidth = 10000

        avatarButton.addTarget(self, action: #selector(userAvatarTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let snapshot {
            avatar.frame = snapshot.avatarRect
            tintIcon.frame = snapshot.tintIconRect
            avatarButton.frame = snapshot.avatarRect
            userHeaderText.frame = snapshot.userHeaderTextRect
            mainText.frame = snapshot.mainTextRect
            mainText.isHidden = snapshot.mainTextRect.size.height <= 0
            pollView.frame = snapshot.pollViewRect
            pollView.isHidden = snapshot.pollViewRect.size.height <= 0
            attachments.frame = snapshot.attachmentsRect
            attachments.isHidden = snapshot.attachmentsRect.size.height <= 0
            renotePreview.frame = snapshot.renoteViewRect
            renotePreview.isHidden = snapshot.renoteViewRect.size.height <= 0
            reactions.frame = snapshot.reactionsRect
            reactions.isHidden = snapshot.reactionsRect.size.height <= 0
            footerText.frame = snapshot.footerTextRect
            operationSeparatorUp.frame = snapshot.operationSeparatorUpRect
            operations.frame = snapshot.operationsRect
            operationSeparatorDown.frame = snapshot.operationSeparatorDownRect
        } else {
            avatar.frame = .zero
            tintIcon.frame = .zero
            avatarButton.frame = .zero
            userHeaderText.frame = .zero
            mainText.frame = .zero
            pollView.frame = .zero
            attachments.frame = .zero
            renotePreview.frame = .zero
            reactions.frame = .zero
            footerText.frame = .zero
            operationSeparatorUp.frame = .zero
            operations.frame = .zero
            operationSeparatorDown.frame = .zero
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
        userHeaderText.attributedText = nil
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
        userHeaderText.attributedText = snapshot.userHeaderText
        mainText.attributedText = snapshot.mainText
        pollView.snapshot = snapshot.voteSnapshot
        attachments.snapshot = snapshot.attachmentSnapshot
        renotePreview.snapshot = snapshot.renoteSnapshot
        reactions.snapshot = snapshot.reactionSnapshot
        footerText.attributedText = snapshot.footerText
        operations.noteId = snapshot.note.noteId

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

extension NoteView {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var note: Note = .missingDataHolder
        var user: User = .unavailable

        var avatarRect: CGRect = .zero
        var tintIconRect: CGRect = .zero
        var userHeaderTextRect: CGRect = .zero
        var userHeaderText: NSMutableAttributedString = .init()
        var mainTextRect: CGRect = .zero
        var mainText: NSMutableAttributedString = .init()
        var pollViewRect: CGRect = .zero
        var attachmentsRect: CGRect = .zero
        var renoteViewRect: CGRect = .zero
        var reactionsRect: CGRect = .zero
        var footerTextRect: CGRect = .zero
        var footerText: NSMutableAttributedString = .init()
        var operationSeparatorUpRect: CGRect = .zero
        var operationsRect: CGRect = .zero
        var operationSeparatorDownRect: CGRect = .zero

        var voteSnapshot: PollView.Snapshot?
        var renoteSnapshot: NotePreviewSimple.Snapshot?
        var attachmentSnapshot: NoteAttachmentView.Snapshot?
        var reactionSnapshot: ReactionStrip.Snapshot?

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(note)
            hasher.combine(user)
            hasher.combine(avatarRect)
            hasher.combine(tintIconRect)
            hasher.combine(userHeaderTextRect)
            hasher.combine(userHeaderText)
            hasher.combine(mainTextRect)
            hasher.combine(mainText)
            hasher.combine(pollViewRect)
            hasher.combine(attachmentsRect)
            hasher.combine(renoteViewRect)
            hasher.combine(reactionsRect)
            hasher.combine(footerTextRect)
            hasher.combine(footerText)
            hasher.combine(operationSeparatorUpRect)
            hasher.combine(operationsRect)
            hasher.combine(operationSeparatorDownRect)
            hasher.combine(voteSnapshot)
            hasher.combine(renoteSnapshot)
            hasher.combine(attachmentSnapshot)
            hasher.combine(reactionSnapshot)
        }
    }
}

extension NoteView.Snapshot {
    struct RenderHint {
        let avatarSize: CGFloat
        weak var context: NoteCell.Context?
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

        let avatarSize = hint.avatarSize
        guard let context = hint.context else { return }

        let verticalSpacing = NoteView.verticalSpacing * 2
        let horizontalSpacing = verticalSpacing

        let textParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = false
            parser.paragraphStyle.lineSpacing = IH.preferredParagraphStyleLineSpacing
            parser.paragraphStyle.paragraphSpacing = verticalSpacing
                - parser.paragraphStyle.lineSpacing
            return parser
        }()

        let avatarRect = CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize)

        let tintIconSize: CGFloat = avatarSize / 3
        let tintIconRect = CGRect(
            x: avatarRect.maxX - tintIconSize,
            y: avatarRect.maxY - tintIconSize,
            width: tintIconSize,
            height: tintIconSize
        )

        let note = context.source?.notes.retain(context.noteId) ?? .missingDataHolder
        let user = context.source?.users.retain(note.userId) ?? User()

        let userText = textParser.compileUserHeader(with: user, lineBreak: true)
        let userTextX = avatarRect.maxX + horizontalSpacing
        let userTextWidth = width - avatarRect.width - horizontalSpacing
        let userTextHeight = userText.measureHeight(usingWidth: userTextWidth)
        let userTextRect: CGRect
        if userTextHeight > avatarRect.height {
            userTextRect = CGRect(
                x: userTextX,
                y: avatarRect.minY,
                width: userTextWidth,
                height: userTextHeight
            )
        } else {
            userTextRect = CGRect(
                x: userTextX,
                y: avatarRect.minY + (avatarRect.height - userTextHeight) / 2,
                width: userTextWidth,
                height: userTextHeight
            )
        }

        let contentStart = max(avatarRect.maxY, userTextRect.maxY) + verticalSpacing

        textParser.options.fontSizeOffset += 2

        let mainText = textParser.compileNoteBody(withNote: note)
        let mainTextFittingSize = mainText.measureHeight(usingWidth: width)
        let mainTextViewRect = CGRect(
            x: 0,
            y: contentStart,
            width: width,
            height: mainText.length > 0 ? mainTextFittingSize : -verticalSpacing
        )

        var voteSnapshot: PollView.Snapshot?
        let pollViewRect: CGRect
        if let vote = note.poll {
            let snapshot = PollView.Snapshot(
                usingWidth: width,
                textParser: textParser,
                poll: vote,
                noteId: note.noteId,
                spacing: verticalSpacing / 2
            )
            voteSnapshot = snapshot
            pollViewRect = CGRect(
                x: 0,
                y: mainTextViewRect.origin.y + mainTextViewRect.size.height + verticalSpacing,
                width: width,
                height: snapshot.height > 0 ? snapshot.height : -verticalSpacing
            )
        } else {
            pollViewRect = CGRect(
                x: 0,
                y: mainTextViewRect.origin.y + mainTextViewRect.size.height + verticalSpacing,
                width: width,
                height: -verticalSpacing
            )
        }

        let attachmentElements = NoteCell.Context.createAttachmentElements(withNote: note)
        let attachmentSnapshot = NoteAttachmentView.Snapshot(usingWidth: width, elements: attachmentElements)
        let attachmentHeight: CGFloat = attachmentSnapshot.height
        let attachmentRect = CGRect(
            x: 0,
            y: pollViewRect.origin.y + pollViewRect.size.height + verticalSpacing,
            width: width,
            height: attachmentHeight > 0 ? attachmentHeight : -verticalSpacing
        )

        let renoteParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = true
            parser.paragraphStyle = textParser.paragraphStyle
            return parser
        }()

        let renoteSnapshot = NotePreviewSimple.Snapshot(usingWidth: width, target: note.renoteId, context: context, textParser: renoteParser)
        let renoteHeight: CGFloat = renoteSnapshot.height
        let renoteRect = CGRect(
            x: 0,
            y: attachmentRect.origin.y + attachmentRect.size.height + verticalSpacing,
            width: width,
            height: renoteHeight > 0 ? renoteHeight : -verticalSpacing
        )

        let footerText = textParser.compileNoteFooter(withNote: note)
        let footerTextSize = footerText
            .measureHeight(usingWidth: width)
        let footerTextRect = CGRect(
            x: 0,
            y: renoteRect.origin.y + renoteRect.size.height + verticalSpacing,
            width: width,
            height: footerTextSize
        )

        let reactionElements = NoteCell.Context.createReactionStripElemetns(withNote: note, source: context.source)
        let reactionSnapshot = ReactionStrip.Snapshot(usingWidth: width, viewElements: reactionElements, limitation: 512)
        let reactionHeight: CGFloat = reactionSnapshot.height
        let reactionRect = CGRect(
            x: 0,
            y: footerTextRect.maxY + verticalSpacing,
            width: width,
            height: reactionHeight > 0 ? reactionHeight : -verticalSpacing
        )

        let operationSepUpRect = CGRect(
            x: 0,
            y: reactionRect.origin.y + reactionRect.size.height + verticalSpacing,
            width: width,
            height: 1
        )

        let operationRect = CGRect(
            x: 0,
            y: operationSepUpRect.maxY + verticalSpacing / 2,
            width: width,
            height: NoteOperationStrip.contentHeight
        )

        let operationSepDownRect = CGRect(
            x: 0,
            y: operationRect.maxY + verticalSpacing / 2,
            width: width,
            height: 1
        )

        self.width = width
        height = operationSepDownRect.maxY
        self.note = note
        self.user = user
        self.avatarRect = avatarRect
        self.tintIconRect = tintIconRect
        userHeaderTextRect = userTextRect
        userHeaderText = userText
        mainTextRect = mainTextViewRect
        self.mainText = mainText
        self.pollViewRect = pollViewRect
        attachmentsRect = attachmentRect
        renoteViewRect = renoteRect
        reactionsRect = reactionRect
        self.footerTextRect = footerTextRect
        self.footerText = footerText
        operationSeparatorUpRect = operationSepUpRect
        operationsRect = operationRect
        operationSeparatorDownRect = operationSepDownRect
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
        avatarRect = .zero
        tintIconRect = .zero
        userHeaderTextRect = .zero
        userHeaderText = .init()
        mainTextRect = .zero
        mainText = .init()
        pollViewRect = .zero
        attachmentsRect = .zero
        renoteViewRect = .zero
        reactionsRect = .zero
        footerTextRect = .zero
        footerText = .init()
        operationSeparatorUpRect = .zero
        operationsRect = .zero
        operationSeparatorDownRect = .zero
        voteSnapshot = nil
        renoteSnapshot = nil
        attachmentSnapshot = nil
        reactionSnapshot = nil
    }
}
