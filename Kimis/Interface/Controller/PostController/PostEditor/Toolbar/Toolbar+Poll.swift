//
//  Toolbar+Poll.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit

extension PostEditorToolbarView {
    func createButtonsForPoll() -> [ToolItemButton] { [
        ToolItemButton(post: post, toolMenu: [
            .init(action: { post, anchor in
                if post.poll == nil {
                    let poll = Post.Poll(expiresAt: nil, choices: ["", ""], multiple: false)
                    post.poll = poll // set once
                } else {
                    let alert = UIAlertController(title: "⚠️", message: "Are you sure you want to remove poll?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                        post.poll = nil
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    anchor.parentViewController?.present(alert, animated: true)
                }
            }),
        ], toolIcon: { post in
            if post.poll == nil {
                return UIImage.fluent(.task_list_add_filled)
            } else {
                return UIImage.fluent(.text_grammar_dismiss)
            }
        }, toolEnabled: { _ in
            true
        }),
    ] }
}
