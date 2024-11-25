//
//  TextParser.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/2.
//

import Foundation
import Source
import UIKit

typealias StringAttribute = [NSAttributedString.Key: Any]

class TextParser {
    weak var source: Source? = Account.shared.source
    static let `default` = TextParser()

    struct TextSize {
        var title: CGFloat = .init(AppConfig.current.defaultNoteFontSize)
        var base: CGFloat = .init(AppConfig.current.defaultNoteFontSize)
        var hint: CGFloat = .init(AppConfig.current.defaultNoteFontSize) - 4
        var foot: CGFloat = .init(AppConfig.current.defaultNoteFontSize) - 4
    }

    var size: TextSize = .init()

    struct TextWeight {
        var base: UIFont.Weight = .regular
        var foot: UIFont.Weight = .regular
        var hint: UIFont.Weight = .semibold
        var title: UIFont.Weight = .bold
    }

    var weight: TextWeight = .init()

    struct TextColor {
        var text: UIColor = .systemBlackAndWhite
        var highlight: UIColor = .accent
        var secondary: UIColor = .systemGray
    }

    var color: TextColor = .init()

    struct Options {
        var compactPreview: Bool = false
        var fontSizeOffset: CGFloat = 0
    }

    var options: Options = .init()

    struct DateFormat {
        var relative: RelativeDateTimeFormatter = {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            formatter.unitsStyle = .abbreviated
            return formatter
        }()

        var absolute: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter
        }()
    }

    var dateFormatters: DateFormat = .init()

    var paragraphStyle: NSMutableParagraphStyle = .init()

    init() {}

    func getFont(size: CGFloat? = nil, weight: UIFont.Weight? = nil) -> UIFont {
        let size = size ?? self.size.base
        let weight = weight ?? self.weight.base
        return UIFont.systemFont(ofSize: size + options.fontSizeOffset, weight: weight)
    }

    func getMonospacedFont(size: CGFloat? = nil, weight: UIFont.Weight? = nil) -> UIFont {
        let size = size ?? self.size.base
        let weight = weight ?? self.weight.base
        return UIFont.monospacedSystemFont(ofSize: size + options.fontSizeOffset, weight: weight)
    }
}

extension NSAttributedString {
    var full: NSRange { .init(location: 0, length: length) }
}

extension TextParser {
    func finalize(_ string: NSMutableAttributedString, defaultHost: String? = nil) -> NSMutableAttributedString {
        deletingProhibitedCharacters(string)
        deletingDollarAttribute(string)
        attributeFullFill(string)
        replaceAllAttributeForMarkdownSyntax(with: string)
        replaceAttributeForHashtag(with: string)
        replaceAttributeForUnifiedUsername(with: string)
        replaceAttributeForEmails(with: string)
        replaceAttributeForSimpleUsername(with: string, defaultHost: defaultHost)
        replaceAttributeForLinks(with: string)
        replaceTinyEmoji(from: string, defaultHost: defaultHost)
        while string.string.hasPrefix(" ") {
            string.deleteCharacters(in: NSRange(location: 0, length: 1))
        }
        while string.string.hasPrefix("\n") {
            string.deleteCharacters(in: NSRange(location: 0, length: 1))
        }
        while string.string.hasSuffix(" ") {
            string.deleteCharacters(in: NSRange(location: string.length - 1, length: 1))
        }
        while string.string.hasSuffix("\n") {
            string.deleteCharacters(in: NSRange(location: string.length - 1, length: 1))
        }
        attributeFullFill(string)
        return string
    }

    static let prohibitedCharacters: [String] = ["\u{2028}"]
    func deletingProhibitedCharacters(_ string: NSMutableAttributedString) {
        for char in Self.prohibitedCharacters {
            let result = checkingResult(withinString: string, matching: char)
            enumerateModifying(string: string, duringRanges: result) { _ in
                .init()
            }
        }
    }

    func attributeFullFill(_ string: NSMutableAttributedString) {
        lazy var supposeToUseFont = getFont(size: size.base, weight: weight.base)
        for idx in 0 ..< string.length {
            let attrs = string.attributes(at: idx, effectiveRange: nil)
            if !attrs.keys.contains(.foregroundColor) {
                string.addAttributes([.foregroundColor: color.text], range: NSRange(location: idx, length: 1))
            }
            if !attrs.keys.contains(.font) {
                string.addAttributes([.font: supposeToUseFont], range: NSRange(location: idx, length: 1))
            }
            if !attrs.keys.contains(.originalFont) {
                string.addAttributes([.originalFont: supposeToUseFont], range: NSRange(location: idx, length: 1))
            }
            if !attrs.keys.contains(.paragraphStyle) {
                string.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: idx, length: 1))
            }
        }
    }

    func colorize(string: NSMutableAttributedString, color: UIColor) {
        string.addAttributes([.foregroundColor: color], range: string.full)
    }

    func connect(strings: [NSMutableAttributedString?], separator: String?) -> NSMutableAttributedString {
        Self.connect(strings: strings, separator: separator)
    }

    static func connect(strings: [NSMutableAttributedString?], separator: String?) -> NSMutableAttributedString {
        let builder = strings
            .compactMap { $0 }
            .filter { $0.length > 0 }
        let ans = NSMutableAttributedString()
        for (idx, string) in builder.enumerated() {
            ans.append(string)
            if let separator, separator.count > 0, idx < builder.count - 1 {
                let prevAttr = string.attributes(at: string.length - 1, effectiveRange: nil)
                ans.append(NSAttributedString(string: separator, attributes: prevAttr))
            }
        }
        return ans
    }
}

extension NSAttributedString.Key {
    static let coreTextRunDelegate = NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)
    static let originalFont = NSAttributedString.Key(rawValue: "NSOriginalFont")
}

extension String {
    func noLineBreak() -> String {
        replacingOccurrences(of: " ", with: "\u{a0}")
            .replacingOccurrences(of: "-", with: "\u{2011}")
    }
}
