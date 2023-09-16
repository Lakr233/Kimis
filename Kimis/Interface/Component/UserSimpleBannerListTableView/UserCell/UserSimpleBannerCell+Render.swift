//
//  UserSimpleBannerCell+Render.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import Combine
import Source
import UIKit

extension UserSimpleBannerCell.Context {
    func renderLayout(usingWidth width: CGFloat) {
        // this is not thread safe impl, setting snapshot = nil may result empty cell
        guard let profile else { return }
        let transformedWidth = IH.containerWidth(usingWidth: width)
        let snapshot = UserPreview.Snapshot(usingWidth: transformedWidth, user: profile)
        cellHeight = snapshot.height
        self.snapshot = snapshot
    }
}
