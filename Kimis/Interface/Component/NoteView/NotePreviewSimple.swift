//
//  NotePreviewSimple.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import Source
import UIKit

class NotePreviewSimple: UIView {
    var snapshot: Snapshot? {
        didSet {
            if snapshot != oldValue { updateNoteData() }
        }
    }

    static let spacing: CGFloat = 8
    static let mainTextLimit: Int = 8
    static let userTextLimit: Int = 1

    let avatar = AvatarView()
    let userText = TextView(editable: false, selectable: false)
    let mainText = TextView(editable: false, selectable: false)
    let pollView = PollView()
    let attachments = NoteAttachmentView()
    let renoteHint = TextView.noneInteractive()

    let coverButton = UIButton()

    init() {
        super.init(frame: .zero)
        layer.borderWidth = 0.5
        layer.cornerRadius = 12
        layer.masksToBounds = true
        clipsToBounds = true

        mainText.textContainer.maximumNumberOfLines = Self.mainTextLimit
        userText.textContainer.maximumNumberOfLines = Self.userTextLimit

        let views: [UIView] = [
            avatar, userText, mainText, pollView, coverButton, attachments, renoteHint,
        ]
        addSubviews(views)

        coverButton.addTarget(self, action: #selector(coverButtonTouched), for: .touchUpInside)
        attachments.disableRadius = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isHidden { return }

        if let snapshot {
            avatar.frame = snapshot.avatarRect
            userText.frame = snapshot.userTextRect
            mainText.frame = snapshot.mainTextRect
            pollView.frame = snapshot.pollViewRect
            attachments.frame = snapshot.attachmentsRect
            renoteHint.frame = snapshot.renoteHintRect

            userText.isHidden = snapshot.userTextRect.size.height <= 0
            mainText.isHidden = snapshot.mainTextRect.size.height <= 0
            pollView.isHidden = snapshot.pollViewRect.size.height <= 0
            attachments.isHidden = snapshot.attachmentsRect.size.height <= 0
            renoteHint.isHidden = snapshot.renoteHintRect.size.height <= 0
        } else {
            avatar.frame = .zero
            userText.frame = .zero
            mainText.frame = .zero
            pollView.frame = .zero
            attachments.frame = .zero
            renoteHint.frame = .zero
        }

        coverButton.frame = bounds

        layer.borderColor = UIColor.systemGray5.cgColor
    }

    func clear() {
        avatar.clear()
        mainText.attributedText = nil
        pollView.snapshot = nil
        attachments.snapshot = nil
        renoteHint.attributedText = nil
    }

    func updateNoteData() {
        guard let snapshot else {
            clear()
            return
        }

        avatar.loadImage(with: .init(url: snapshot.user.avatarUrl, blurHash: snapshot.user.avatarBlurHash))
        userText.attributedText = snapshot.userText
        mainText.attributedText = snapshot.mainText
        pollView.snapshot = snapshot.pollViewSnapshot
        attachments.snapshot = snapshot.attachmentsSnapshot
        renoteHint.attributedText = snapshot.renoteHintText
    }

    @objc func coverButtonTouched() {
        guard let hint = snapshot?.renderHint as? Snapshot.RenderHint,
              let noteId = hint.target
        else { return }
        ControllerRouting.pushing(tag: .note, referencer: self, associatedData: noteId)

        setNeedsLayout()
    }
}

extension NotePreviewSimple {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var note: Note = .missingDataHolder
        var user: User = .unavailable

        var avatarRect: CGRect = .zero
        var userTextRect: CGRect = .zero
        var userText: NSMutableAttributedString = .init()
        var mainTextRect: CGRect = .zero
        var mainText: NSMutableAttributedString = .init()
        var pollViewRect: CGRect = .zero
        var pollViewSnapshot: PollView.Snapshot?
        var attachmentsRect: CGRect = .zero
        var attachmentsSnapshot: NoteAttachmentView.Snapshot?
        var renoteHintRect: CGRect = .zero
        var renoteHintText: NSMutableAttributedString = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(note)
            hasher.combine(user)
            hasher.combine(avatarRect)
            hasher.combine(userTextRect)
            hasher.combine(userText)
            hasher.combine(mainTextRect)
            hasher.combine(mainText)
            hasher.combine(pollViewRect)
            hasher.combine(pollViewSnapshot)
            hasher.combine(attachmentsRect)
            hasher.combine(attachmentsSnapshot)
            hasher.combine(renoteHintRect)
            hasher.combine(renoteHintText)
        }
    }
}

extension NotePreviewSimple.Snapshot {
    struct RenderHint {
        let target: NoteID?
        weak var context: NoteCell.Context?
        let textParser: TextParser
    }

    convenience init(usingWidth width: CGFloat, target: NoteID?, context: NoteCell.Context) {
        let textParser: TextParser = {
            let parser = TextParser()
            parser.options.fontSizeOffset = IH.preferredFontSizeOffset(usingWidth: width)
            parser.options.compactPreview = true
            parser.paragraphStyle.lineSpacing = IH.preferredParagraphStyleLineSpacing
            parser.paragraphStyle.paragraphSpacing = 0
            return parser
        }()
        self.init(usingWidth: width, target: target, context: context, textParser: textParser)
    }

    convenience init(usingWidth width: CGFloat, target: NoteID?, context: NoteCell.Context, textParser: TextParser) {
        self.init()
        render(usingWidth: width, target: target, context: context, textParser: textParser)
    }

    func render(usingWidth width: CGFloat, target: NoteID?, context: NoteCell.Context, textParser: TextParser) {
        renderHint = RenderHint(target: target, context: context, textParser: textParser)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }

        guard let target = hint.target else {
            invalidate()
            return
        }

        let context = hint.context
        let textParser = hint.textParser

        let spacing = NotePreviewSimple.spacing

        let targetNote = context?.source?.notes.retain(target) ?? .missingDataHolder
        let targetUser = context?.source?.users.retain(targetNote.userId) ?? .init()

        let avatarRect = CGRect(
            x: spacing,
            y: spacing,
            width: 24,
            height: 24,
        )

        let userTextRect: CGRect

        let userText = textParser.compileRenoteUserHeader(with: targetUser)
        let userTextWidth = width - spacing * 3 - avatarRect.width
        let userTextHeight = userText
            .measureHeight(usingWidth: userTextWidth, lineLimit: NotePreviewSimple.userTextLimit)
        if userTextHeight > avatarRect.height {
            userTextRect = CGRect(
                x: avatarRect.maxX + spacing,
                y: avatarRect.minY,
                width: userTextWidth,
                height: userTextHeight,
            )
        } else {
            userTextRect = CGRect(
                x: avatarRect.maxX + spacing,
                y: avatarRect.minY + (avatarRect.height - userTextHeight) / 2,
                width: userTextWidth,
                height: userTextHeight,
            )
        }

        let contentWidth = width - spacing * 2

        let mainText = textParser.compileNoteBody(withNote: targetNote)
        let mainTextHeight = mainText
            .measureHeight(usingWidth: contentWidth, lineLimit: NotePreviewSimple.mainTextLimit)
        let mainTextRect = CGRect(
            x: spacing,
            y: max(userTextRect.maxY, avatarRect.maxY) + spacing,
            width: contentWidth,
            height: mainTextHeight > 0 && mainText.length > 0 ? mainTextHeight : -spacing,
        )

        let pollViewRect: CGRect
        var pollViewSnapshot: PollView.Snapshot?
        if let poll = targetNote.poll {
            let snapshot = PollView.Snapshot(
                usingWidth: contentWidth,
                textParser: textParser,
                poll: poll,
                noteId: targetNote.noteId,
                spacing: spacing,
            )
            pollViewSnapshot = snapshot
            pollViewRect = .init(
                x: spacing,
                y: mainTextRect.origin.y + mainTextRect.size.height + spacing,
                width: contentWidth,
                height: snapshot.height > 0 ? snapshot.height : -spacing,
            )
        } else {
            pollViewRect = .init(
                x: spacing,
                y: mainTextRect.origin.y + mainTextRect.size.height + spacing,
                width: contentWidth,
                height: -spacing,
            )
        }

        let attachmentElements = NoteCell.Context.createAttachmentElements(withNote: targetNote)
        let attachmentSnapshot = NoteAttachmentView.Snapshot(usingWidth: width, elements: attachmentElements, limit: 4)
        let attachmentHeight = attachmentSnapshot.height
        let attachmentsRect = CGRect(
            x: 0,
            y: pollViewRect.origin.y + pollViewRect.size.height + spacing,
            width: width,
            height: attachmentHeight > 0 ? attachmentHeight : -spacing,
        )

        var renoteHintRect: CGRect = .zero
        let finalHeight: CGFloat

        let renoteHintText = textParser.compileRenoteHint(
            withRenote: context?.source?.notes.retain(targetNote.renoteId),
        )
        if renoteHintText.length > 0 {
            let renoteHintHeight = renoteHintText
                .measureHeight(usingWidth: contentWidth)
            renoteHintRect = CGRect(
                x: spacing,
                y: attachmentsRect.origin.y + attachmentsRect.size.height + spacing,
                width: contentWidth,
                height: renoteHintText.length > 0 ? renoteHintHeight : -spacing,
            )
            finalHeight = renoteHintRect.origin.y + renoteHintRect.size.height + spacing
        } else {
            finalHeight = attachmentsRect.origin.y + attachmentsRect.size.height +
                (attachmentsRect.size.height > 0 ? 0 : spacing)
        }

        self.width = width
        height = finalHeight
        note = targetNote
        user = targetUser
        self.avatarRect = avatarRect
        self.userTextRect = userTextRect
        self.userText = userText
        self.mainTextRect = mainTextRect
        self.mainText = mainText
        self.pollViewRect = pollViewRect
        self.pollViewSnapshot = pollViewSnapshot
        self.attachmentsRect = attachmentsRect
        attachmentsSnapshot = attachmentSnapshot
        self.renoteHintRect = renoteHintRect
        self.renoteHintText = renoteHintText
    }

    func invalidate() {
        width = 0
        height = 0
        note = .missingDataHolder
        user = .unavailable
        avatarRect = .zero
        userTextRect = .zero
        userText = .init()
        mainTextRect = .zero
        mainText = .init()
        pollViewRect = .zero
        pollViewSnapshot = nil
        attachmentsRect = .zero
        attachmentsSnapshot = nil
        renoteHintRect = .zero
        renoteHintText = .init()
    }
}
