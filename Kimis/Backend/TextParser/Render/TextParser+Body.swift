//
//  TextParser+Text.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import Foundation
import UIKit

extension TextParser {
    func compileNoteBody(withNote note: Note?, removeDuplicatedNewLines: Bool = false) -> NSMutableAttributedString {
        guard let note else { return .init(string: "") }
        guard let user = source?.users.retain(note.userId) else { return .init(string: "") }

        var texts = [String]()
        if let cw = note.contentWarning {
            texts.append("\(cw)")
        }
        var content = note.text
        while removeDuplicatedNewLines, content.contains("\n\n") {
            content = content.replacingOccurrences(of: "\n\n", with: "\n")
        }
        texts.append(content)

        let text = texts.joined(separator: "\n")
        let ans = NSMutableAttributedString(string: text)

        if options.compactPreview {
            enumeratedModifyingWithRegex(withinString: ans, matching: .repliesMentionPrefix) { string in
                if string.length < 30 { return string }
                return NSMutableAttributedString(string: "`[@...]` ", attributes: [
                    .foregroundColor: UIColor.accent,
                ])
            }
        }

        return finalize(ans, defaultHost: user.host)
    }

    func compileRenoteHint(withRenote note: Note?) -> NSMutableAttributedString {
        guard let note else { return .init() }
        guard let user = source?.users.retain(note.userId) else { return .init(string: "") }
        var desc = note.url?.absoluteString
        if desc == nil { desc = "https://\(user.host)/notes/\(note.noteId)" }
        if desc == nil { desc = note.noteId }
        guard let desc else { return .init() }
        let ans = NSMutableAttributedString(string: "RE: \(desc)", attributes: [
            .font: getFont(size: size.foot, weight: weight.foot),
            .foregroundColor: color.secondary,
        ])
        return finalize(ans, defaultHost: user.host)
    }
}
