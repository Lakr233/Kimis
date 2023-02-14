//
//  UIButton+DefaultButton.swift
//  Kimis
//
//  Created by Kagurazaka Tsuki on 2023/02/03.
//

import UIKit

extension UIButton {
    func defaultButton(icon: UIImage? = nil) {
        imageView?.contentMode = .scaleAspectFit
        if let icon {
            setImage(icon, for: .normal)
        }
        isPointerInteractionEnabled = true
    }
}

@propertyWrapper
struct DefaultButton {
    var wrappedValue = UIButton()

    init(icon: UIImage? = nil) {
        wrappedValue.defaultButton(icon: icon)
    }
}
