//
//  TextParser+Hashtag.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import Foundation
import UIKit

extension TextParser {
    func replaceAttributeForHashtag(with string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .hashtag) { string in
            if string.attributes.keys.contains(.link) { return nil }
            guard let messagePayload = string.string.base64Encoded else { return nil }
            let str = "hashtag://" + messagePayload
            string.addAttributes([
                .link: str,
                .foregroundColor: color.highlight,
            ], range: string.full)
            return string
        }
    }
}
