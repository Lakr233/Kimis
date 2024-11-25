//
//  CGPoint.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/18.
//

import CoreGraphics
import Foundation

extension CGPoint: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
