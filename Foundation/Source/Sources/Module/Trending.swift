//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/27.
//

import Foundation

public class Trending: Codable, Identifiable, Hashable, Equatable {
    public var id: Int { hashValue }

    public init(tag: String, chart: [Int] = [], usersCount: Int = 0) {
        self.tag = tag
        self.chart = chart
        self.usersCount = usersCount
    }

    public var tag: String
    public var chart: [Int]
    public var usersCount: Int

    public func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
        hasher.combine(chart)
        hasher.combine(usersCount)
    }

    public static func == (lhs: Trending, rhs: Trending) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
