//
//  Note.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/21.
//

import Foundation
import Module

extension Note {
    static let missingNoteId = "__missing_note__"

    static let missingDataHolder: Note = .init(
        noteId: missingNoteId,
        url: nil,
        date: .init(timeIntervalSince1970: 0),
        text: "This note is not available at this time.",
        visibility: "public",
        userId: "__missing_note_user_id__"
    )
}
