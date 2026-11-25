//
//  FoldRegionView.swift
//  Kimis
//
//  Created by Lakr Aream on 2026/11/25.
//

import SnapKit
import UIKit

/// Finds the fold of a foldable iPhone while it is partially folded, so a
/// screen can keep its text and controls off it. Pin it to the edges of the
/// view that lays out the content. Flat open, closed, and on every other
/// device there is no fold, `fold` stays nil and both regions are the safe area.
class FoldRegionView: UIView {
    enum Fold {
        /// Folded like a book: `firstRegion` is left of the fold, `secondRegion` right of it.
        case vertical
        /// Folded like a laptop: `firstRegion` is above the fold, `secondRegion` below it.
        case horizontal
    }

    private(set) var fold: Fold?
    let firstRegion = UILayoutGuide()
    let secondRegion = UILayoutGuide()
    var foldDidChange: (() -> Void)?

    private var foldFrame: CGRect?
    private var previousSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addLayoutGuide(firstRegion)
        addLayoutGuide(secondRegion)
        layoutRegions()
        if #available(iOS 27.1, *) {
            addInteraction(UIHingeInteraction { [weak self] _, _ in
                self?.setNeedsUpdateConstraints()
            })
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != bounds.size {
            previousSize = bounds.size
            setNeedsUpdateConstraints()
        }
    }

    override func updateConstraints() {
        var frame: CGRect?
        if #available(iOS 27.1, *) {
            frame = reservedRegions(kind: .division).first?.frame
        }
        if frame != foldFrame {
            foldFrame = frame
            layoutRegions()
            let newFold: Fold? = frame.map { $0.width < $0.height ? Fold.vertical : Fold.horizontal }
            if newFold != fold {
                fold = newFold
                foldDidChange?()
            }
        }
        super.updateConstraints()
    }

    private func layoutRegions() {
        let safeArea = safeAreaLayoutGuide
        guard let foldFrame else {
            firstRegion.snp.remakeConstraints { $0.edges.equalTo(safeArea) }
            secondRegion.snp.remakeConstraints { $0.edges.equalTo(safeArea) }
            return
        }
        if foldFrame.width < foldFrame.height {
            firstRegion.snp.remakeConstraints { make in
                make.top.bottom.left.equalTo(safeArea)
                make.right.equalTo(self.snp.left).offset(foldFrame.minX)
            }
            secondRegion.snp.remakeConstraints { make in
                make.top.bottom.right.equalTo(safeArea)
                make.left.equalTo(self.snp.left).offset(foldFrame.maxX)
            }
        } else {
            firstRegion.snp.remakeConstraints { make in
                make.left.right.top.equalTo(safeArea)
                make.bottom.equalTo(self.snp.top).offset(foldFrame.minY)
            }
            secondRegion.snp.remakeConstraints { make in
                make.left.right.bottom.equalTo(safeArea)
                make.top.equalTo(self.snp.top).offset(foldFrame.maxY)
            }
        }
    }
}
