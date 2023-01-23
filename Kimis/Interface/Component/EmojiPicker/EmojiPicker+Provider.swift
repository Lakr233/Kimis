//
//  EmojiPicker+Provider.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/20.
//

import Foundation
import Source

class EmojiProvider {
    weak var source: Source? = Account.shared.source

    struct Emoji: Codable, Hashable, Equatable {
        var emoji: String
        var description: String
        var category: String
        var aliases: [String]
        var tags: [String]
        var unicodeVersion: String?
        var iosVersion: String?
    }

    private static let bundledEmoji: [String: [Emoji]] = {
        guard let res = Bundle.main.url(forResource: "Emoji", withExtension: "json"),
              let data = try? Data(contentsOf: res),
              let array = try? JSONDecoder().decode([Emoji].self, from: data)
        else {
            assertionFailure("invalid resources")
            return [:]
        }
        var result = [String: [Emoji]]()
        for item in array {
            result[item.category, default: []].append(item)
        }
        return result
    }()

    func retainStaticEmojis() -> [String: [Emoji]] {
        Self.bundledEmoji
    }

    func retainInstanceEmojis() -> [Emoji] {
        guard let source else { return [] }
        var build = [Emoji]()
        for key in source.emojis.keys {
            let url = source.host
                .appendingPathComponent("emoji")
                .appendingPathComponent(key)
                .appendingPathExtension("webp")
            let emoji = Emoji(
                emoji: ":\(key):",
                description: url.absoluteString,
                category: "",
                aliases: [],
                tags: [],
                unicodeVersion: nil,
                iosVersion: nil
            )
            build.append(emoji)
        }
        return build
    }

    func obtainRecentUsed() -> [String] {
        source?.properties.readProperty(fromKey: .recentEmoji, defaultValue: []) ?? []
    }

    func insertRecentUsed(emoji: String) {
        var build = obtainRecentUsed()
        build = [emoji] + build
        if build.count > 50 {
            build.removeLast(build.count - 50)
        }
        build.removeDuplicates()
        source?.properties.setProperty(toKey: .recentEmoji, withObject: build)
    }
}
