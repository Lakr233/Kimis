//
//  NSAttributeString.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/21.
//

import Foundation
import UIKit

extension NSAttributedString {
    func fixup(_ width: CGFloat) -> CGFloat {
        width.nextUp
    }

    func measureWidth() -> CGFloat {
        if string.trimmingCharacters(in: .whitespacesAndNewlines).count <= 0 {
            return 0
        }
        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer(size: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        _ = layoutManager.glyphRange(for: textContainer)
        let testWidth = layoutManager.usedRect(for: textContainer).size.width
        return fixup(testWidth)
    }

    func measureHeight(usingWidth width: CGFloat, lineLimit: Int = 0, lineBreakMode: NSLineBreakMode = .byTruncatingTail) -> CGFloat {
        if string.trimmingCharacters(in: .whitespacesAndNewlines).count <= 0 {
            return 0
        }
        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer(size: CGSize(width: width, height: .infinity))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.maximumNumberOfLines = lineLimit
        textContainer.lineBreakMode = lineBreakMode
        textContainer.lineFragmentPadding = 0
        _ = layoutManager.glyphRange(for: textContainer)
        let testHeight = layoutManager.usedRect(for: textContainer).size.height
        return fixup(testHeight)
    }
}
