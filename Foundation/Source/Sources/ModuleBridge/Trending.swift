//
//  Trending.swift
//
//
//  Created by Lakr Aream on 2022/11/27.
//

import Foundation
import Module
import NetworkModule

public extension Trending {
    static func converting(_ object: MKTrend) -> Trending? {
        Trending(
            tag: object.tag,
            chart: object.chart,
            usersCount: object.usersCount,
        )
    }
}
