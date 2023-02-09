//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation

public extension TimelineSource {
    enum Endpoint: String, Codable, CaseIterable {
        case home
        case local
        case recommended
        case hybrid
        case global
    }
}
