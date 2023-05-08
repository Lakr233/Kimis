//
//  CGRect.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import CoreGraphics
import Foundation

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine([
            origin.x,
            origin.y,
            size.width,
            size.height,
        ])
    }
}
