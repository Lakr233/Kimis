//
//  CGSize.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/2.
//

import Foundation

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine([width, height])
    }
}
