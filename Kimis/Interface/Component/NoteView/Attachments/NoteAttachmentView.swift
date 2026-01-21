//
//  NoteAttachmentView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/14.
//

import UIKit

class NoteAttachmentView: UIView {
    var snapshot: Snapshot? {
        didSet {
            if snapshot != oldValue { updateSnapshot() }
        }
    }

    var views: [NoteAttachmentView.Preview] = []
    let moreLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = .white
        view.backgroundColor = .systemTeal
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.numberOfLines = 1
        view.minimumScaleFactor = 0.5
        view.adjustsFontSizeToFitWidth = true
        view.font = .rounded(ofSize: 16, weight: .regular)
        return view
    }()

    static let spacing: CGFloat = 2
    static let defaultCorner: CGFloat = IH.contentCornerRadius

    var disableRadius = false

    init() {
        super.init(frame: .zero)
        layer.borderWidth = 0.5
        layer.cornerRadius = Self.defaultCorner
        layer.masksToBounds = true
        clipsToBounds = true
        addSubview(moreLabel)
        moreLabel.layer.maskedCorners = [.layerMinXMinYCorner]
        backgroundColor = .systemGray5
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isHidden { return }

        layer.borderColor = UIColor.systemGray5.cgColor

        if disableRadius {
            layer.cornerRadius = 0
        } else if let superCorner = superview?.layer.cornerRadius, superCorner > 0,
                  let superWidth = superview?.frame.width, superWidth > 0
        {
            let padding = (superWidth - bounds.width) / 2
            layer.cornerRadius = max(superCorner - padding, 0)
        } else {
            layer.cornerRadius = Self.defaultCorner
        }

        if let snapshot {
            for idx in 0 ..< snapshot.viewFrames.count {
                views[safe: idx]?.frame = snapshot.viewFrames[safe: idx] ?? .zero
                views[safe: idx]?.isHidden = snapshot.viewFrames[safe: idx]?.size ?? .zero == .zero
            }
        }

        let moreLabelSize = CGSize(width: 48, height: 24)
        let moreLabelPadding: CGFloat = 0
        moreLabel.frame = CGRect(
            x: bounds.width - moreLabelSize.width - moreLabelPadding,
            y: bounds.height - moreLabelSize.height - moreLabelPadding,
            width: moreLabelSize.width,
            height: moreLabelSize.height,
        )
        var moreLabelCornerRadius = layer.cornerRadius - moreLabelPadding
        if moreLabelCornerRadius < 0 { moreLabelCornerRadius = 4 }
        moreLabel.layer.cornerRadius = moreLabelCornerRadius
    }

    func updateSnapshot() {
        guard let snapshot else { return }
        if views.count != snapshot.viewFrames.count {
            views.forEach { $0.removeFromSuperview() }
            views = []
            for _ in 0 ..< snapshot.viewFrames.count {
                let preview = Preview()
                views.append(preview)
                addSubview(preview)
            }
        }
        assert(views.count == snapshot.viewFrames.count)
        for idx in 0 ..< views.count {
            if let element = snapshot.elements[safe: idx] {
                views[idx].element = element
                views[idx].isHidden = false
            } else {
                views[idx].isHidden = true
            }
        }
        moreLabel.text = "+\(snapshot.moreCount)"
        moreLabel.isHidden = snapshot.moreCount <= 0
        bringSubviewToFront(moreLabel)
    }
}
