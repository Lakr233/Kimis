//
// Created by Kagurazaka Tsuki on 2023-01-21.
//

import UIKit

extension TapAreaEnlargedButton {
    @objc func buttonHoverAnimation(_ gesture: UIHoverGestureRecognizer) {
        let speed = 0.15
        switch gesture.state {
        case .began, .changed:
            UIView.animate(withDuration: speed, delay: 0, options: .curveEaseInOut) {
                self.tintColor = .accent
            }
        case .ended:
            UIView.animate(withDuration: speed, delay: 0, options: .curveEaseInOut) {
                self.tintColor = NoteOperationStrip.buttonColor
            }
        default: // unhandled state, fall back to the default color
            tintColor = NoteOperationStrip.buttonColor
        }
    }
}
