//
//  PollView+Snapshot.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/1.
//

import Source
import UIKit

extension PollView {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var vote: Note.Poll = .init(multiple: false, expiresAt: nil, choices: [])

        var interactive: Bool = false

        var containerRect: CGRect = .zero
        var elementsRect: [CGRect] = [] // relative to container rect
        var elementsSnapshot: [ChoiceView.Snapshot] = []

        var footerTextRect: CGRect = .zero
        var footerText: NSMutableAttributedString = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(vote)
            hasher.combine(interactive)
            hasher.combine(containerRect)
            hasher.combine(elementsRect)
            hasher.combine(elementsSnapshot)
            hasher.combine(footerTextRect)
            hasher.combine(footerText)
        }
    }
}

extension PollView.Snapshot {
    struct RenderHint {
        let textParser: TextParser
        let poll: Note.Poll
        let noteId: NoteID
        let spacing: CGFloat
    }

    convenience init(usingWidth width: CGFloat, textParser: TextParser, poll: Note.Poll, noteId: NoteID, spacing: CGFloat) {
        self.init()
        render(usingWidth: width, textParser: textParser, poll: poll, noteId: noteId, spacing: spacing)
    }

    func render(usingWidth width: CGFloat, textParser: TextParser, poll: Note.Poll, noteId: NoteID, spacing: CGFloat) {
        renderHint = RenderHint(textParser: textParser, poll: poll, noteId: noteId, spacing: spacing)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }
        let textParser = hint.textParser
        let poll = hint.poll
        let noteId = hint.noteId
        let spacing = hint.spacing

        var elementsRect: [CGRect] = []
        var elementsSnapshot: [PollView.ChoiceView.Snapshot] = []

        let interactive = poll.isInteractive

        var voteButtonHeight: CGFloat = 50
        var currentAnchor: CGFloat = 0
        for (idx, element) in poll.choices.enumerated() {
            let snapshot = PollView.ChoiceView.Snapshot(
                usingWidth: width,
                element: element,
                interactive: interactive,
                noteId: noteId,
                index: idx,
                textParser: textParser,
            )
            elementsSnapshot.append(snapshot)
            elementsRect.append(.init(
                x: 0,
                y: currentAnchor,
                width: width,
                height: snapshot.height,
            ))
            currentAnchor += snapshot.height + spacing
            voteButtonHeight = min(voteButtonHeight, snapshot.height)
        }

        currentAnchor -= spacing
        let containerRect = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: currentAnchor,
        )

        let footerText = textParser.compileVoteFooter(withPoll: poll)
        let footerTextHeight = footerText.measureHeight(usingWidth: width)
        let footerTextRect = CGRect(
            x: 0,
            y: currentAnchor + spacing,
            width: width,
            height: footerTextHeight,
        )

        self.width = width
        height = footerTextRect.maxY
        vote = poll
        self.interactive = interactive
        self.containerRect = containerRect
        self.elementsRect = elementsRect
        self.elementsSnapshot = elementsSnapshot
        self.footerTextRect = footerTextRect
        self.footerText = footerText
    }

    func invalidate() {
        width = 0
        height = 0
        vote = .init(multiple: false, expiresAt: nil, choices: [])
        interactive = false
        containerRect = .zero
        elementsRect = []
        elementsSnapshot = []
        footerTextRect = .zero
        footerText = .init()
    }
}
