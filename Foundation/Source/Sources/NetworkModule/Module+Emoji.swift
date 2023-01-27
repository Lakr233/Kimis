//
//  Network+NMEmoji.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/3.
//

import BetterCodable
import Foundation

public struct NMEmoji: Codable {
    public var name: String
    @LossyOptional public var category: String?
    @LossyOptional public var aliases: [String]?
}
