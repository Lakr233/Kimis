//
//  UIImage+Placeholder.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import UIKit

extension UIImage {
    static func placeholder() -> UIImage {
        let size = CGSize(width: 1, height: 1)
        return UIGraphicsImageRenderer(size: size)
            .image { rendererContext in
                UIColor.systemGray5.setFill()
                rendererContext.fill(CGRect(origin: .zero, size: size))
            }
    }
}
