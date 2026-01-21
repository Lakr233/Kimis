//
//  Context+Render.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation
import Source

extension NotificationCell.Context {
    func renderLayout(usingWidth width: CGFloat, source: Source?) {
        // this is not thread safe impl, setting snapshot = nil may result empty cell
        let containerWidth = IH.containerWidth(usingWidth: width)
        switch kind {
        case .main:
            if let notification {
                let snapshot = NotificationCell.MainCell.Snapshot(
                    usingWidth: containerWidth,
                    rendering: notification,
                    source: source,
                )
                cellHeight = snapshot.height
                self.snapshot = snapshot
            }
        case .separator: break
        case .progress: break
        case .unsupported: break
        }
    }
}
