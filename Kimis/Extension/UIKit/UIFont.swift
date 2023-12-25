//
//  UIFont.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/2.
//

import UIKit

extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font: UIFont = if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            UIFont(descriptor: descriptor, size: size)
        } else {
            systemFont
        }
        return font
    }
}
