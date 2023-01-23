//
//  UserViewController+Scroll.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/28.
//

import UIKit

extension UserViewController {
    func didScroll(toPosition: CGPoint) {
        if toPosition.y < 0 {
            userView.bannerImageViewExtraHeight = abs(toPosition.y)
        } else if userView.bannerImageViewExtraHeight > 0 {
            userView.bannerImageViewExtraHeight = 0
        }

        if toPosition.y > tableView.contentSize.height - tableView.frame.height - 10 {
            if !isLoadingNotes { updateNotes() }
        }

        var titleTextViewAlpha: CGFloat = toPosition.y / 20
        if titleTextViewAlpha < 0 { titleTextViewAlpha = 0 }
        if titleTextViewAlpha > 1 { titleTextViewAlpha = 1 }
        if titleTextView.alpha != titleTextViewAlpha {
            titleTextView.alpha = titleTextViewAlpha
        }
    }
}
