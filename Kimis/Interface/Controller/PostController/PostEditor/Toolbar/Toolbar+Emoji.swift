//
//  Toolbar+Emoji.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit

extension PostEditorToolbarView {
    func createButtonsForEmoji() -> [ToolItemButton] { [
        ToolItemButton(post: post, toolMenu: [
            .init(action: { post, anchor in
                let picker = EmojiPickerViewController(sourceView: anchor) { emoji in
                    if let selection = post.selectionHint,
                       post.text.utf16.count >= selection.location, // selection related to attr text len
                       let mod = (post.text as NSString).mutableCopy() as? NSMutableString
                    {
                        mod.insert(emoji.emoji, at: selection.location)
                        post.text = mod as String
                    } else {
                        post.text += emoji.emoji
                    }
                }
                anchor.parentViewController?.present(picker, animated: true)
            }),
        ], toolIcon: { _ in
            UIImage.fluent(.emoji_add_filled)
        }, toolEnabled: { _ in
            true
        }),
    ] }
}
