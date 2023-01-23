//
//  TextParser+Text.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import Foundation

extension TextParser {
    func trimToPlainText(from text: String) -> String {
        let ans = NSMutableAttributedString(string: text)
        enumeratedModifyingWithRegex(withinString: ans, matching: .emoji) { _ in
            NSMutableAttributedString()
        }
        return finalize(ans)
            .string
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
