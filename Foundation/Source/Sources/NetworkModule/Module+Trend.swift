//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/27.
//

import BetterCodable
import Foundation

public struct MKTrend: Codable {
    public let tag: String
    public let chart: [Int]
    public let usersCount: Int
}
