//
//  LeftBottomCurveLine.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/19.
//

import UIKit

class LeftBottomCurveLine: UIView {
    let lineWidth: CGFloat
    let lineRadius: CGFloat
    let lineColor: UIColor

    init(lineWidth: CGFloat, lineRadius: CGFloat, lineColor: UIColor) {
        self.lineWidth = lineWidth
        self.lineRadius = lineRadius
        self.lineColor = lineColor

        super.init(frame: .zero)

        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let centerOffset = lineWidth / 2

        lineColor.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: centerOffset, y: 0))
        path.addLine(to: CGPoint(x: centerOffset, y: rect.height - lineRadius - centerOffset))
        let leftBottom = CGPoint(x: centerOffset, y: rect.height - centerOffset)
        path.addCurve(
            to: CGPoint(x: lineRadius + centerOffset, y: rect.height - centerOffset),
            controlPoint1: leftBottom,
            controlPoint2: leftBottom
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - centerOffset))
        path.lineWidth = lineWidth
        path.stroke()
    }
}
