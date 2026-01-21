//
//  ChoiceView+Snapshot.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/1.
//

import Source
import UIKit

extension PollView.ChoiceView {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var noteId: NoteID = ""
        var index: Int = 0

        var element: Note.Poll.Choice = .init(text: "", votes: 0, isVoted: false, percent: 0)
        var interactive: Bool = false

        var iconRect: CGRect = .zero
        var textRect: CGRect = .zero
        var text: NSMutableAttributedString = .init()
        var countTextRect: CGRect = .zero
        var countText: NSMutableAttributedString = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(noteId)
            hasher.combine(index)
            hasher.combine(element)
            hasher.combine(interactive)
            hasher.combine(iconRect)
            hasher.combine(textRect)
            hasher.combine(text)
            hasher.combine(countTextRect)
            hasher.combine(countText)
        }
    }
}

extension PollView.ChoiceView.Snapshot {
    struct RenderHint {
        let element: Note.Poll.Choice
        let interactive: Bool
        let noteId: NoteID
        let index: Int
        let textParser: TextParser
    }

    convenience init(usingWidth width: CGFloat, element: Note.Poll.Choice, interactive: Bool, noteId: NoteID, index: Int, textParser: TextParser) {
        self.init()
        render(usingWidth: width, element: element, interactive: interactive, noteId: noteId, index: index, textParser: textParser)
    }

    func render(usingWidth width: CGFloat, element: Note.Poll.Choice, interactive: Bool, noteId: NoteID, index: Int, textParser: TextParser) {
        renderHint = RenderHint(element: element, interactive: interactive, noteId: noteId, index: index, textParser: textParser)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }

        let element = hint.element
        let interactive = hint.interactive
        let noteId = hint.noteId
        let index = hint.index
        let textParser = hint.textParser

        let verticalPadding: CGFloat = 4
        let horizontalPadding: CGFloat = 8
        let iconSize: CGFloat = 20

        var iconRect = CGRect(
            x: horizontalPadding,
            y: verticalPadding,
            width: iconSize,
            height: iconSize,
        )

        let countText = textParser.finalize(NSMutableAttributedString(string: "x\(element.votes)", attributes: [
            .font: textParser.getMonospacedFont(size: textParser.size.foot),
            .foregroundColor: UIColor.systemBlackAndWhite.withAlphaComponent(0.5),
        ]))
        let countTextWidth = countText.measureWidth()
        let countTextHeight = countText.measureHeight(usingWidth: .infinity)
        var countTextRect = if countTextHeight < iconSize {
            CGRect(
                x: width - horizontalPadding - countTextWidth,
                y: verticalPadding + (iconSize - countTextHeight) / 2,
                width: countTextWidth,
                height: countTextHeight,
            )
        } else {
            CGRect(
                x: width - horizontalPadding - countTextWidth,
                y: verticalPadding,
                width: countTextWidth,
                height: countTextHeight,
            )
        }

        let text = textParser.finalize(.init(string: element.text))
        let textWidth = countTextRect.minX - horizontalPadding - horizontalPadding - iconRect.maxX
        let textHeight = text.measureHeight(usingWidth: textWidth)
        var textRect = if textHeight < iconSize {
            CGRect(
                x: iconRect.maxX + horizontalPadding,
                y: verticalPadding + (iconSize - textHeight) / 2,
                width: textWidth,
                height: textHeight,
            )
        } else {
            CGRect(
                x: iconRect.maxX + horizontalPadding,
                y: verticalPadding,
                width: textWidth,
                height: textHeight,
            )
        }

        let height = max(textRect.maxY, countTextRect.maxY, 32) + verticalPadding

        // fix to dynamic center
        textRect = CGRect(
            x: textRect.origin.x,
            y: (height - textRect.size.height) / 2,
            width: textRect.size.width,
            height: textRect.size.height,
        )
        let finalIconHeight = max(iconSize, textRect.size.height)
        iconRect = CGRect(
            x: iconRect.origin.x,
            y: (height - finalIconHeight) / 2,
            width: iconSize,
            height: finalIconHeight,
        )
        countTextRect = CGRect(
            x: countTextRect.origin.x,
            y: (height - countTextRect.size.height) / 2,
            width: countTextRect.size.width,
            height: countTextRect.size.height,
        )

        self.width = width
        self.height = height
        self.noteId = noteId
        self.index = index
        self.element = element
        self.interactive = interactive
        self.iconRect = iconRect
        self.textRect = textRect
        self.text = text
        self.countTextRect = countTextRect
        self.countText = countText
    }

    func invalidate() {
        width = 0
        height = 0
        noteId = ""
        index = 0
        element = .init(text: "", votes: 0, isVoted: false, percent: 0)
        interactive = false
        iconRect = .zero
        textRect = .zero
        text = .init()
        countTextRect = .zero
        countText = .init()
    }
}
