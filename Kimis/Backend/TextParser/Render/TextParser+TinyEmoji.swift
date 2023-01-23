//
//  TextParser+TinyEmoji.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import Foundation
import SDWebImage
import UIKit

extension TextParser {
    func replaceTinyEmoji(from string: NSMutableAttributedString, defaultHost: String? = nil) {
        guard let endpoint = source?.host.appendingPathComponent("emoji") else { return }
        enumeratedModifyingWithRegex(withinString: string, matching: .emoji) { string in
            guard string.string.hasPrefix(":"),
                  string.string.hasSuffix(":"),
                  attributeAvailableForEmojiReplacement(attribute: string.attributes)
            else { return nil }
            let emoji = String(string.string.dropFirst().dropLast())
            let size = (string.attributes[.font] as? UIFont)?.pointSize ?? self.size.base
            if let defaultHost, defaultHost.lowercased() != source?.host.host?.lowercased() {
                let url = endpoint.appendingPathComponent("\(emoji)@\(defaultHost).webp")
                return NSMutableAttributedString(
                    attachment: RemoteImageAttachment(url: url, size: CGSize(width: size, height: size))
                )
            } else {
                let url = endpoint.appendingPathComponent("\(emoji).webp")
                return NSMutableAttributedString(
                    attachment: RemoteImageAttachment(url: url, size: CGSize(width: size, height: size))
                )
            }
        }
    }

    private func attributeAvailableForEmojiReplacement(attribute: [NSAttributedString.Key: Any]) -> Bool {
        for attr in attribute {
            if attr.key == .font,
               let font = attr.value as? UIFont,
               font.fontName == getMonospacedFont().fontName
               || font.fontName.lowercased().contains("monospaced")
            {
                return false
            }
            if attr.key == .link,
               let link = attr.value as? String,
               link.hasPrefix("http")
            {
                return false
            }
            if attr.key == .link,
               let link = attr.value as? URL,
               let scheme = link.scheme,
               scheme.hasPrefix("http")
            {
                return false
            }
        }
        return true
    }
}
