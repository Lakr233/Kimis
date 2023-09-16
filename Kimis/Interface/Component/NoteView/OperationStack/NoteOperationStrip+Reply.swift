//
//  NoteOperationStrip+Reply.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import UIKit

extension NoteOperationStrip {
    @objc func replyButtonTapped() {
        debugPrint(#function)
        replyButton.shineAnimation()
        ControllerRouting.pushing(
            tag: .post,
            referencer: self,
            associatedData: PostController.PostContext(renote: nil, reply: noteId)
        )
    }
}
