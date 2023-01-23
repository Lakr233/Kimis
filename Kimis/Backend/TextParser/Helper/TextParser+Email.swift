//
//  TextParser+Email.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/29.
//

import Foundation
import UIKit

extension TextParser {
    private func appendingColorAndLinkAttributeForEmail(withinString string: NSMutableAttributedString, color: UIColor) {
        enumeratedModifyingWithRegex(withinString: string, matching: .mail) { string in
            guard !string.attributes.keys.contains(.link) else { return nil }
            guard let url = URL(string: "mailto:" + string.string) else { return nil }
            var modifier = string.string
            var attributeBuilder = string.attributes
            attributeBuilder[.foregroundColor] = color
            attributeBuilder[.link] = url.absoluteString
            modifier = modifier.removingPercentEncoding ?? modifier
            let result = NSMutableAttributedString(string: modifier, attributes: attributeBuilder)
            return result
        }
    }

    func replaceAttributeForEmails(with string: NSMutableAttributedString) {
        appendingColorAndLinkAttributeForEmail(withinString: string, color: color.highlight)
    }
}
