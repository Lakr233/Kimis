//
//  TextParser+Markdown.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/8.
//

import Foundation
import UIKit

extension TextParser {
    func replaceAllAttributeForMarkdownSyntax(with string: NSMutableAttributedString) {
        replaceAttributeForMarkdownLink(with: string)
        replaceAttributeForMarkdownBold(with: string)
        replaceAttributeForMarkdownStrikethrough(with: string)
        replaceAttributeForMarkdownMonospaceMultiline(with: string)
        replaceAttributeForMarkdownMonospaceInline(with: string)
        replaceAttributeForMarkdownQuote(with: string)
    }

    func replaceAttributeForMarkdownLink(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .markdownAttachment) { string in
            guard string.string.hasPrefix("["),
                  string.string.contains("]"),
                  string.string.contains("("),
                  string.string.hasSuffix(")")
            else {
                return nil
            }
            var link = string.string.components(separatedBy: "]")
                .last ?? ""
            guard link.hasPrefix("("), link.hasSuffix(")") else { return nil }
            link.removeFirst()
            link.removeLast()
            if link.hasPrefix("<"), link.hasSuffix(">") {
                link.removeFirst()
                link.removeLast()
            }
            guard !link.isEmpty else { return nil }
            guard URL(string: link) != nil else { return nil }
            let attribute: StringAttribute = [
                .foregroundColor: color.highlight,
                .link: link,
            ]
            string.addAttributes(attribute, range: string.full)
            if options.compactPreview {
                let attributes = string.attributes
                var desc = string.string
                desc = desc.components(separatedBy: "]").first ?? ""
                desc = desc.components(separatedBy: "[").last ?? ""
                return NSMutableAttributedString(string: desc, attributes: attributes)
            } else {
                return string
            }
        }
    }

    func replaceAttributeForMarkdownBold(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .markdownBold) { string in
            let fontSize = (string.attributes[.font] as? UIFont)?.pointSize ?? size.base
            string.addAttributes([
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            ], range: string.full)
            if string.string.hasPrefix("**"), string.string.hasSuffix("**") {
                string.deleteCharacters(in: NSRange(location: 0, length: 2))
                string.deleteCharacters(in: NSRange(location: string.length - 2, length: 2))
            }
            return string
        }
    }

    func replaceAttributeForMarkdownStrikethrough(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .markdownStrikethrough) { string in
            string.addAttributes([
                .strikethroughColor: (string.attributes[.foregroundColor] as? UIColor) ?? UIColor.systemBlackAndWhite,
                .strikethroughStyle: 2,
            ], range: string.full)
            if string.string.hasPrefix("~~"), string.string.hasSuffix("~~") {
                string.deleteCharacters(in: NSRange(location: 0, length: 2))
                string.deleteCharacters(in: NSRange(location: string.length - 2, length: 2))
            }
            return string
        }
    }

    func replaceAttributeForMarkdownMonospaceInline(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .markdownMonospaceInline) { string in
            let fontSize = (string.attributes[.font] as? UIFont)?.pointSize ?? size.base
            let fontWeight = (string.attributes[.font] as? UIFont)?.weight ?? weight.base
            string.addAttributes([
                .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: fontWeight),
            ], range: string.full)
            if string.string.hasPrefix("`"), string.string.hasSuffix("`") {
                string.deleteCharacters(in: NSRange(location: 0, length: 1))
                string.deleteCharacters(in: NSRange(location: string.length - 1, length: 1))
            }
            return string
        }
    }

    func replaceAttributeForMarkdownMonospaceMultiline(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .markdownMonospaceMultiLine) { string in
            let fontSize = (string.attributes[.font] as? UIFont)?.pointSize ?? size.base
            let fontWeight = (string.attributes[.font] as? UIFont)?.weight ?? weight.base
            string.addAttributes([
                .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: fontWeight),
            ], range: string.full)
            if string.string.hasPrefix("```\n"), string.string.hasSuffix("\n```") {
                string.deleteCharacters(in: NSRange(location: 0, length: 4))
                string.deleteCharacters(in: NSRange(location: string.length - 4, length: 4))
            }
            return string
        }
    }

    func replaceAttributeForMarkdownQuote(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .markdownQuote) { string in
            let fontSize = (string.attributes[.font] as? UIFont)?.pointSize ?? size.base

            let leadingQuote = NSMutableAttributedString(string: "『 ", attributes: string.attributes)
            leadingQuote.addAttributes([
                .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor.accent,
            ], range: leadingQuote.full)

            let trailingQuote = NSMutableAttributedString(string: " 』", attributes: string.attributes)
            trailingQuote.addAttributes([
                .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor.accent,
            ], range: leadingQuote.full)

            if string.string.hasPrefix("> ") {
                string.deleteCharacters(in: NSRange(location: 0, length: 2))
            } else if string.string.hasPrefix(">") {
                string.deleteCharacters(in: NSRange(location: 0, length: 1))
            }

            return connect(strings: [leadingQuote, string, trailingQuote], separator: nil)
        }
    }
}
