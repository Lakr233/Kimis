//
//  UIButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/7.
//

import UIKit

class TapAreaEnlargedButton: UIButton {
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        var enlarge: CGFloat = 14
        if frame.width > 50 || frame.height > 50 { enlarge = 0 }
        return bounds.insetBy(dx: -enlarge, dy: -enlarge).contains(point)
    }
}

extension UIButton {
    func presentMenu() {
        // _presentMenuAtLocation:
        guard let interaction = interactions.first,
              let data = Data(base64Encoded: "X3ByZXNlbnRNZW51QXRMb2NhdGlvbjo="),
              let str = String(data: data, encoding: .utf8)
        else {
            return
        }
        let selector = NSSelectorFromString(str)
        guard interaction.responds(to: selector) else {
            return
        }
        interaction.perform(selector, with: CGPoint.zero)
    }
}
