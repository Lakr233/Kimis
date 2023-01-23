//
//  Emoji.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/3.
//

import Foundation

public class Emoji: Codable, Identifiable, Hashable, Equatable {
    public var id: String { name }
    public var name: String
    public var category: String?
    public var aliases: [String]?

    public init(name: String, category: String? = nil, aliases: [String]? = nil) {
        self.name = name
        self.category = category
        self.aliases = aliases
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(category)
        hasher.combine(aliases)
    }

    public static func == (lhs: Emoji, rhs: Emoji) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
