//
//  InterfaceHint.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation

enum IH {
    static let contentMaxWidth: CGFloat = 700
    static let contentCornerRadius: CGFloat = 12
    static let contentMiniItemHeight: CGFloat = 32
    static let contentMiniItemCornerRadius: CGFloat = 5

    static let connectorWidth: CGFloat = 2

    static let preferredParagraphStyleLineSpacing: CGFloat = 2

    static func preferredFontSizeOffset(usingWidth width: CGFloat) -> CGFloat {
        if width < 300 { return -4 }
        if width < 400 { return -2 }
        return 0
    }

    static func preferredPadding(usingWidth width: CGFloat) -> CGFloat {
//        if width > 500 { return 20 }
        if width > 400 { return 16 }
        return 10
    }

    static func containerWidth(usingWidth width: CGFloat, maxWidth: CGFloat = IH.contentMaxWidth) -> CGFloat {
        if width > maxWidth { return maxWidth }
        return width
    }

    static func preferredAvatarSizeOffset(usingWidth width: CGFloat) -> CGFloat {
        if width < 200 { return -18 }
        if width < 300 { return -12 }
        if width < 400 { return -6 }
        return 0
    }
}
