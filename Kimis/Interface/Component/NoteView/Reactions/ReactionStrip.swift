//
//  ReactionStrip.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/19.
//

import UIKit

class ReactionStrip: UIView {
    static let spacing: CGFloat = 4
    static let elementSize = CGSize(width: IH.contentMiniItemHeight * 2, height: IH.contentMiniItemHeight)

    var snapshot: Snapshot? {
        didSet {
            if snapshot != oldValue { updateSnapshot() }
        }
    }

    var views = [UIView]()

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isHidden { return }

        if let snapshot {
            for idx in 0 ..< snapshot.viewRects.count {
                views[safe: idx]?.frame = snapshot.viewRects[safe: idx] ?? .zero
            }
        } else {
            removeSubviews()
        }
    }

    func updateSnapshot() {
        removeSubviews()
        guard let snapshot else { return }
        views = []
        var hitLimit = false
        for idx in 0 ..< snapshot.viewElements.count {
            if idx >= snapshot.limitation {
                hitLimit = true
                break
            }
            let element = snapshot.viewElements[idx]
            if let text = element.text {
                let view = ReactionStrip.EmojiView(emoji: text, count: element.count, highlight: element.isUserReaction)
                view.representReaction = element
                views.append(view)
            } else if let url = element.url {
                let view = ReactionStrip.ImageView(url: url, count: element.count, highlight: element.isUserReaction)
                view.representReaction = element
                views.append(view)
            }
        }
        if hitLimit {
            views.append(MoreView())
        }
        addSubviews(views)
    }
}
