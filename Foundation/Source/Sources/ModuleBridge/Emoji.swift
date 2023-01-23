//
//  Emoji.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/3.
//

import Foundation
import Module
import NetworkModule

public extension Emoji {
    static func converting(_ object: NMEmoji) -> Emoji? {
        .init(name: object.name, category: object.category, aliases: object.aliases)
    }
}
