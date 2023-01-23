//
//  OperationStack+Reaction.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import UIKit

extension NoteOperationStrip {
    @objc func reactButtonTapped() {
        debugPrint(#function)
        reactButton.shineAnimation()

        guard let note else { return }
        if note.userReaction.isEmpty {
            reactionCreate()
        } else {
            reactionDelete()
        }
    }

    private func reactionCreate() {
        let picker = EmojiPickerViewController(sourceView: reactButton) { [weak self] emoji in
            guard let self, let source = self.source, let noteId = self.noteId else { return }
            self.callingReactionUpdate(source: source, onNote: noteId, emojiOrDelete: emoji.emoji)
        }
        associatedControllers.append(picker)
        parentViewController?.present(picker, animated: true)
    }

    private func reactionDelete() {
        guard let source, let noteId else { return }
        callingReactionUpdate(source: source, onNote: noteId, emojiOrDelete: nil)
    }

    private func callingReactionUpdate(source: Source, onNote note: NoteID, emojiOrDelete: String?) {
        startProgressIndicator()
        DispatchQueue.global().async {
            let ret = source.req.requestNoteReaction(reactionIdentifier: emojiOrDelete, forNote: note)
            if ret == nil { presentError("Unable to update") }
            withMainActor { [weak self] in self?.updateDataSource() }
        }
    }

    private func startProgressIndicator() {
        reactionIndicator.isHidden = false
        reactionIndicator.alpha = 1
        reactionIndicator.startAnimating()
        reactButton.alpha = 0
        reactButton.isUserInteractionEnabled = false
        reactButton.isPointerInteractionEnabled = false
    }
}
