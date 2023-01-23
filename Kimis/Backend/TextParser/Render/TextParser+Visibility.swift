//
//  TextParser+Visibility.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/7.
//

import Foundation
import UIKit

extension TextParser {
    func createRestrictedVisibilityHint(size: CGFloat? = nil) -> NSMutableAttributedString {
        let size = size ?? self.size.base
        let attachment = ImageAttachment(
            image: .fluent(.lock_open_filled),
            size: CGSize(width: size, height: size),
            tintColor: color.highlight
        )
        return NSMutableAttributedString(attachment: attachment)
    }

    func createAdminHint(size: CGFloat? = nil) -> NSMutableAttributedString {
        let size = size ?? self.size.base
        let attachment = ImageAttachment(
            image: .fluent(.shield_checkmark_filled),
            size: CGSize(width: size, height: size),
            tintColor: color.highlight
        )
        return NSMutableAttributedString(attachment: attachment)
    }
}
