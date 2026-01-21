//
//  NoteAttachmentView+Snapshot.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

extension NoteAttachmentView {
    class Snapshot: AnySnapshot {
        var id: UUID = .init()

        var renderHint: Any?

        var width: CGFloat = 0
        var height: CGFloat = .zero

        var limit: Int = 0
        var viewFrames: [CGRect] = []
        var elements: [NoteAttachmentView.Elemet] = []
        var moreCount: Int = 0

        func hash(into hasher: inout Hasher) {
            hasher.combine(width)
            hasher.combine(height)
            hasher.combine(limit)
            hasher.combine(viewFrames)
            hasher.combine(elements)
            hasher.combine(moreCount)
        }
    }
}

extension NoteAttachmentView.Snapshot {
    struct RenderHint {
        let elements: [NoteAttachmentView.Elemet]
        let limit: Int
    }

    convenience init(usingWidth width: CGFloat, elements: [NoteAttachmentView.Elemet], limit: Int = 0) {
        self.init()
        render(usingWidth: width, elements: elements, limit: limit)
    }

    func render(usingWidth width: CGFloat, elements: [NoteAttachmentView.Elemet], limit: Int = 0) {
        renderHint = RenderHint(elements: elements, limit: limit)
        render(usingWidth: width)
    }

    func render(usingWidth width: CGFloat) {
        prepareForRender()
        defer { afterRender() }

        guard let hint = renderHint as? RenderHint else {
            assertionFailure()
            return
        }

        let elements = hint.elements
        let limit = hint.limit

        let width = width
        let spacing = NoteAttachmentView.spacing

        var decisionHeight: CGFloat = width / 16 * 9
        var elementsContainer: [NoteAttachmentView.Elemet] = []
        if limit <= 0 {
            elementsContainer = elements
        } else {
            for idx in 0 ..< limit {
                if let element = elements[safe: idx] {
                    elementsContainer.append(element)
                } else { break }
            }
        }

        var rects = [CGRect]()
        for _ in 0 ..< elementsContainer.count {
            rects.append(.zero)
        }

        let requiredHeight: CGFloat = 100

        switch elementsContainer.count {
        case 0:
            decisionHeight = 0
        case 1:
            if width > 0, let size = elementsContainer[0].previewSize {
                let imageWidth = size.width
                let imageHeight = size.height
                decisionHeight = width / imageWidth * imageHeight
            }
            let lowerBounds: CGFloat = requiredHeight
            let upperBounds: CGFloat = 450
            if decisionHeight < lowerBounds { decisionHeight = lowerBounds }
            if decisionHeight > upperBounds { decisionHeight = upperBounds }
            decisionHeight = decisionHeight.rounded()
            rects[0] = CGRect(x: 0, y: 0, width: width, height: decisionHeight)
        case 2:
            let eachWidth = (width - spacing) / 2
            decisionHeight = eachWidth
            if decisionHeight < requiredHeight { decisionHeight = requiredHeight }
            decisionHeight = decisionHeight.rounded()
            rects[0] = CGRect(x: 0, y: 0, width: eachWidth, height: decisionHeight)
            rects[1] = CGRect(x: width - eachWidth, y: 0, width: eachWidth, height: decisionHeight)
        case 3:
            let eachWidth = (width - spacing * 2) / 3
            decisionHeight = eachWidth
            if decisionHeight < requiredHeight { decisionHeight = requiredHeight }
            decisionHeight = decisionHeight.rounded()
            rects[0] = CGRect(x: 0, y: 0, width: eachWidth, height: decisionHeight)
            rects[1] = CGRect(x: eachWidth + spacing, y: 0, width: eachWidth, height: decisionHeight)
            rects[2] = CGRect(x: width - eachWidth, y: 0, width: eachWidth, height: decisionHeight)
        case 4:
            let eachWidth = (width - spacing) / 2
            var eachHeight = eachWidth * 9 / 16
            if eachHeight < requiredHeight { eachHeight = requiredHeight }
            eachHeight = eachHeight.rounded()
            decisionHeight = eachHeight * 2 + spacing
            rects[0] = CGRect(x: 0, y: 0, width: eachWidth, height: eachHeight)
            rects[1] = CGRect(x: eachWidth + spacing, y: 0, width: eachWidth, height: eachHeight)
            rects[2] = CGRect(x: 0, y: eachHeight + spacing, width: eachWidth, height: eachHeight)
            rects[3] = CGRect(x: eachWidth + spacing, y: eachHeight + spacing, width: eachWidth, height: eachHeight)
        default:
            var eachWidth: CGFloat = width * 0.33
            if eachWidth < 160 { eachWidth = 160 }
            if eachWidth > 320 { eachWidth = 320 }
            var lineCount = Int(width / (eachWidth + spacing))
            var preferredRatio: CGFloat = 3 / 4
            if elementsContainer.count == 6 {
                lineCount = 3
                preferredRatio = 1
            }
            if elementsContainer.count == 9 {
                lineCount = 3
                preferredRatio = 1
            }
            if elementsContainer.count == 16 {
                lineCount = 4
                preferredRatio = 1
            }
            if lineCount <= 1 {
                lineCount = 1
                eachWidth = width
            } else {
                eachWidth = (width - (CGFloat(lineCount) - 1) * spacing) / CGFloat(lineCount)
            }
            var eachHeight = eachWidth * preferredRatio
            if eachHeight < requiredHeight { eachHeight = requiredHeight }
            eachHeight = eachHeight.rounded()

            for idx in 0 ..< rects.count {
                let x: Int = idx % lineCount
                let y: Int = idx / lineCount
                rects[idx] = CGRect(
                    x: CGFloat(x) * (eachWidth + spacing),
                    y: CGFloat(y) * (eachHeight + spacing),
                    width: eachWidth,
                    height: eachHeight,
                )
            }
        }

        decisionHeight = rects.last?.maxY ?? 0

        let moreCount = limit > 0 ? elements.count - limit : 0

        self.width = width
        height = decisionHeight
        self.limit = limit
        viewFrames = rects
        self.elements = elements
        self.moreCount = moreCount
    }

    func invalidate() {
        width = 0
        height = .zero
        limit = 0
        viewFrames = []
        elements = []
        moreCount = 0
    }
}
