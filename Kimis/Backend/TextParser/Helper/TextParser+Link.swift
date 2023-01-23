//
//  TextParser+Link.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/10.
//

import Foundation
import IDNA
import UIKit

extension TextParser {
    private func appendingColorAndLinkAttributeForURL(withinString string: NSMutableAttributedString, color: UIColor, compactLongLink: Bool = false) {
        enumeratedModifyingWithRegex(withinString: string, matching: .link) { string in
            guard let url = URL(string: string.string) else { return nil }
            var modifier = string.string
            if compactLongLink {
                let trimPrefix = ["http://", "https://"]
                for prefix in trimPrefix {
                    if modifier.contains(prefix) { modifier.removeFirst(prefix.count) }
                }
                if modifier.count > 20 {
                    modifier.removeLast(modifier.count - 20)
                    modifier.append("...")
                }
            }
            var attributeBuilder = string.attributes
            attributeBuilder[.foregroundColor] = color
            attributeBuilder[.link] = url.absoluteString
            modifier = modifier.removingPercentEncoding ?? modifier
            let result = NSMutableAttributedString(string: modifier, attributes: attributeBuilder)
            decodingIDNAIfNeeded(modifyingStringInPlace: result)
            return result
        }
    }

    func replaceAttributeForLinks(with string: NSMutableAttributedString) {
        appendingColorAndLinkAttributeForURL(withinString: string, color: color.highlight, compactLongLink: options.compactPreview)
    }
}
