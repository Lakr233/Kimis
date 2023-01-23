//
//  ReactionStrip+Snapshot.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

extension ReactionStrip {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = 0

        var viewRects: [CGRect] = []
        var viewElements: [ReactionStrip.Element] = []
        var limitation: Int = 0

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(viewRects)
            hasher.combine(viewElements)
            hasher.combine(limitation)
        }
    }
}

extension ReactionStrip.Snapshot {
    struct RenderHint {
        let viewElements: [ReactionStrip.Element]
        let limitation: Int
    }

    convenience init(usingWidth width: CGFloat, viewElements: [ReactionStrip.Element], limitation: Int) {
        self.init()
        render(usingWidth: width, viewElements: viewElements, limitation: limitation)
    }

    func render(usingWidth width: CGFloat, viewElements: [ReactionStrip.Element], limitation: Int) {
        renderHint = RenderHint(viewElements: viewElements, limitation: limitation)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }

        let elements = hint.viewElements
        let limitation = hint.limitation

        if elements.isEmpty { return }

        var xAnchor: CGFloat = 0
        var yAnchor: CGFloat = 0

        var rects = [CGRect]()

        var hitLimit = false
        for idx in 0 ..< elements.count {
            if idx >= limitation {
                hitLimit = true
                break
            }
            let rect = Self.steppingRectsMake(
                xAnchor: &xAnchor,
                yAnchor: &yAnchor,
                width: width,
                size: ReactionStrip.elementSize,
                spacing: ReactionStrip.spacing
            )
            rects.append(rect)
        }

        if hitLimit {
            let rect = Self.steppingRectsMake(
                xAnchor: &xAnchor,
                yAnchor: &yAnchor,
                width: width,
                size: ReactionStrip.elementSize,
                spacing: ReactionStrip.spacing
            )
            rects.append(rect)
        }

        self.width = width
        height = rects.last?.maxY ?? 0
        viewRects = rects
        viewElements = elements
        self.limitation = limitation
    }

    static func steppingRectsMake(xAnchor: inout CGFloat, yAnchor: inout CGFloat, width: CGFloat, size: CGSize, spacing: CGFloat) -> CGRect {
        if width < size.width { return .zero }
        let rect = CGRect(
            x: xAnchor,
            y: yAnchor,
            width: size.width,
            height: size.height
        )
        if rect.maxX > width {
            if xAnchor == 0 { return CGRect.zero }
            xAnchor = 0
            yAnchor += (size.height + spacing)
            return steppingRectsMake(xAnchor: &xAnchor, yAnchor: &yAnchor, width: width, size: size, spacing: spacing)
        } else {
            xAnchor += (size.width + spacing)
        }
        return rect
    }

    func invalidate() {
        width = 0
        height = 0
        viewRects = []
        viewElements = []
        limitation = 0
    }
}
