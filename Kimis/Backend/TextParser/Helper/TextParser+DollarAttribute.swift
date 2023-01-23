//
//  TextParser+Adv.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/5.
//

import Foundation

extension TextParser {
    func deletingDollarAttribute(_ string: NSMutableAttributedString) {
        var found = true
        var depth = 8
        while found, depth > 0 {
            depth -= 1
            found = false
            enumeratedModifyingWithRegex(withinString: string, matching: .dollarAttribute) { string in
                guard string.string.hasPrefix("$["),
                      string.string.hasSuffix("]"),
                      string.string.contains(" ")
                else {
                    return nil
                }
                string.deleteCharacters(in: NSRange(location: string.length - 1, length: 1))
                string.deleteCharacters(in: NSRange(location: 0, length: 2))
                while !string.string.hasPrefix(" "), string.length > 0 {
                    string.deleteCharacters(in: NSRange(location: 0, length: 1))
                }
                guard string.string.hasPrefix(" ") else {
                    return nil
                }
                string.deleteCharacters(in: NSRange(location: 0, length: 1))
                found = true
                return string
            }
        }
    }
}
