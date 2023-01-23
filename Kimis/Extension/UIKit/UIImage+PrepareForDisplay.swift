//
//  UIImage+PrepareForDisplay.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/22.
//

import SDWebImage
import UIKit

extension UIImage {
    func decodeForDisplay() -> UIImage? {
        assert(!Thread.isMainThread)
        if sd_isDecoded { return self }
        if #available(iOS 15.0, *) {
            return self.preparingForDisplay()
        }
        #if targetEnvironment(macCatalyst)
            if #available(macCatalyst 15.0, *) {
                return self.preparingForDisplay()
            }
        #endif

        // fallback when not available, not actually try to call image IO
        // TODO: CGImage Load!
        return self
    }
}
