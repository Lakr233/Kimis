//
//  Swift.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import Foundation

@inline(__always)
func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        for item in items {
            Swift.print(item, separator: separator, terminator: terminator)
        }
    #endif
}

#if DEBUG
    import SDWebImage

    func clearSDWebImageCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
    }
#endif
