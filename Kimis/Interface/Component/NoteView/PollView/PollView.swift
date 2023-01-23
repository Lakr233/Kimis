//
//  PollView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/1.
//

import Source
import UIKit

class PollView: UIView {
    var snapshot: Snapshot? {
        didSet {
            if snapshot != oldValue { updateDataSource() }
        }
    }

    let elementContainer = UIView()
    let footerText: TextView = .init(editable: false, selectable: false, disableLink: true)

    init() {
        super.init(frame: .zero)
        addSubviews([elementContainer, footerText])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var progress: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if let snapshot {
            elementContainer.frame = snapshot.containerRect
            for (idx, rect) in snapshot.elementsRect.enumerated() {
                elementContainer.subviews[safe: idx]?.frame = rect
            }
            footerText.frame = snapshot.footerTextRect
        } else {
            elementContainer.frame = .zero
            footerText.frame = .zero
        }
    }

    func clear() {
        elementContainer.removeSubviews()
        footerText.attributedText = nil
    }

    func updateDataSource() {
        clear()
        guard let snapshot else { return }
        let views = snapshot.elementsSnapshot.map {
            let view = ChoiceView()
            view.snapshot = $0
            return view
        }
        elementContainer.addSubviews(views)
        footerText.attributedText = snapshot.footerText

        setNeedsLayout()
    }
}
