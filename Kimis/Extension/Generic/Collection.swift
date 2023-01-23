//
//  Collection.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import Foundation

extension Array {
    var middle: Element? {
        guard count != 0 else { return nil }
        let middleIndex = (count > 1 ? count - 1 : count) / 2
        return self[middleIndex]
    }
}
