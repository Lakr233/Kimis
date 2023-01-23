//
//  OperationStack+Renote.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import UIKit

extension NoteOperationStrip {
    @objc func renoteButtonTapped() {
        debugPrint(#function)
        renoteButton.shineAnimation()
        ControllerRouting.pushing(
            tag: .post,
            referencer: self,
            associatedData: PostController.PostContext(renote: noteId, reply: nil)
        )
    }
}
