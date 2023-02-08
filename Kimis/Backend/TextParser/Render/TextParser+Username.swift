//
//  TextParser+Username.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import Foundation
import UIKit

extension TextParser {
    func replaceAttributeForSimpleUsername(with string: NSMutableAttributedString, defaultHost: String? = nil) {
        enumeratedModifyingWithRegex(withinString: string, matching: .username) { string in
            guard !string.attributes.keys.contains(.link) else { return nil }
            var username = string.string
            if let defaultHost { username += "@\(defaultHost)" }
            guard let message = username.base64Encoded else { return nil }
            let link = "username://" + message
            guard URL(string: link) != nil else { return nil }
            string.addAttributes([.link: link], range: string.full)
            string.addAttributes([.foregroundColor: color.highlight], range: string.full)
            return string
        }
    }

    func replaceAttributeForUnifiedUsername(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .unifiedUsername) { string in
            guard !string.attributes.keys.contains(.link) else { return nil }
            guard let message = string.string.base64Encoded else { return nil }
            let link = "username://" + message
            guard URL(string: link) != nil else { return nil }
            string.addAttributes([.link: link], range: string.full)
            string.addAttributes([.foregroundColor: color.highlight], range: string.full)
            decodingIDNAIfNeeded(modifyingStringInPlace: string)
            return string
        }
    }
}
