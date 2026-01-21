//
//  SpoilerView.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit

class SpoilerView: UIView {
    private let emitter: CAEmitterCell
    private let emitterLayer: CAEmitterLayer

    private let blurBackground = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemThinMaterialDark),
    )
    private let emitterView = UIView()

    override init(frame: CGRect) {
        let emitter = CAEmitterCell()
        emitter.scale = 0.8
        emitter.contentsScale = 1.8
        emitter.emissionRange = .pi * 2.0
        emitter.lifetime = 1.0
        emitter.velocityRange = 20.0
        emitter.name = "dustCell"
        emitter.alphaRange = 1.0
        emitter.setValue("point", forKey: "particleType")
        emitter.setValue(3.0, forKey: "mass")
        emitter.setValue(2.0, forKey: "massRange")
        self.emitter = emitter

        let fingerAttractor = Self.createEmitterBehavior(type: "simpleAttractor")
        fingerAttractor.setValue("fingerAttractor", forKey: "name")

        let alphaBehavior = Self.createEmitterBehavior(type: "valueOverLife")
        alphaBehavior.setValue("color.alpha", forKey: "keyPath")
        alphaBehavior.setValue([0.0, 0.0, 1.0, 0.0, -1.0], forKey: "values")
        alphaBehavior.setValue(true, forKey: "additive")

        let behaviors = [fingerAttractor, alphaBehavior]

        let emitterLayer = CAEmitterLayer()
        emitterLayer.masksToBounds = true
        emitterLayer.allowsGroupOpacity = true
        emitterLayer.lifetime = 1
        emitterLayer.emitterCells = [emitter]
        emitterLayer.emitterPosition = CGPoint(x: 0, y: 0)
        emitterLayer.seed = arc4random()
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)
        emitterLayer.emitterShape = CAEmitterLayerEmitterShape(rawValue: "rectangles")
        emitterLayer.setValue(behaviors, forKey: "emitterBehaviors")

        emitterLayer.setValue(4.0, forKeyPath: "emitterBehaviors.fingerAttractor.stiffness")
        emitterLayer.setValue(false, forKeyPath: "emitterBehaviors.fingerAttractor.enabled")

        self.emitterLayer = emitterLayer

        super.init(frame: frame)

        layer.masksToBounds = true

        addSubview(blurBackground)
        addSubview(emitterView)
        emitterView.layer.addSublayer(emitterLayer)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tap)

        prepareEmitterColor()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        prepareEmitterColor()
        setNeedsLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        prepareEmitterColor()
    }

    func prepareEmitterColor() {
        let color = UIColor.white.withAlphaComponent(0.5).cgColor
        emitter.color = color
        emitter.contents = Self.createCGImage(
            withColor: color,
            withSize: CGSize(width: 2, height: 2),
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.size.width > 0,
              bounds.size.height > 0
        else {
            return
        }

        blurBackground.frame = bounds
        emitterView.frame = bounds

        let size = bounds.size
        emitter.birthRate = Float(min(100_000, size.width * size.height * 0.05))
        emitterLayer.frame = CGRect(origin: CGPoint(), size: size)
        let rects = [CGRect](repeating: bounds, count: 1)
        emitterLayer.setValue(rects as NSArray, forKey: "emitterRects")
        let radius = max(size.width, size.height)
        emitterLayer.setValue(radius, forKeyPath: "emitterBehaviors.fingerAttractor.radius")
        emitterLayer.setValue(radius * -0.5, forKeyPath: "emitterBehaviors.fingerAttractor.falloff")
    }

    var requestedHidden = false

    @objc func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        guard !requestedHidden else { return }
        requestedHidden = true
        let position = gestureRecognizer.location(in: self)
        emitterLayer.setValue(true, forKeyPath: "emitterBehaviors.fingerAttractor.enabled")
        emitterLayer.setValue(position, forKeyPath: "emitterBehaviors.fingerAttractor.position")
        // full animation is designed to end in 0.75
        withMainActor {
            self.createCircleMaskAnimation(forView: self, beginAt: position)
        }
        withMainActor(delay: 0.25) {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.alpha = 0
            } completion: { _ in
                self.hide()
                self.emitterLayer.setValue(false, forKeyPath: "emitterBehaviors.fingerAttractor.enabled")
            }
        }
    }

    func createCircleMaskAnimation(forView view: UIView, beginAt position: CGPoint) {
        let shapeLayer = CAShapeLayer()
        let fullRectPath = UIBezierPath(rect: view.bounds)
        let beginCircle = UIBezierPath(ovalIn: CGRect(origin: position, size: .zero))
        fullRectPath.append(beginCircle)

        let size = sqrt(pow(view.bounds.width, 2) + pow(view.bounds.height, 2)) * 1.1
        let finalRectPath = UIBezierPath(rect: CGRect(
            center: view.bounds.center,
            size: CGSize(width: size, height: size),
        ))
        let finalCircle = UIBezierPath(ovalIn: CGRect(
            center: view.bounds.center,
            size: CGSize(width: size, height: size),
        ))
        finalRectPath.append(finalCircle)

        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = fullRectPath.cgPath
        pathAnimation.toValue = finalRectPath.cgPath
        pathAnimation.duration = 0.75
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pathAnimation.fillMode = .forwards
        pathAnimation.isRemovedOnCompletion = false

        shapeLayer.path = beginCircle.cgPath
        shapeLayer.fillRule = .evenOdd
        shapeLayer.add(pathAnimation, forKey: "path")

        view.layer.mask = shapeLayer
    }

    func hide() {
        alpha = 0
        isHidden = true
    }

    func show() {
        UIView.performWithoutAnimation {
            alpha = 1
            isHidden = false
            requestedHidden = false
        }
        emitterLayer.setValue(false, forKeyPath: "emitterBehaviors.fingerAttractor.enabled")
    }
}

extension SpoilerView {
    static func createCGImage(
        withColor color: CGColor = CGColor(gray: 0.5, alpha: 1),
        withSize size: CGSize = CGSize(width: 1, height: 1),
    ) -> CGImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        UIColor(cgColor: color).setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.cgImage!
    }
}

extension SpoilerView {
    static func createEmitterBehavior(type: String) -> NSObject {
        let selector = ["behaviorWith", "Type:"].joined(separator: "")
        let behaviorClass: NSObject.Type = NSClassFromString([
            "CA", "Emitter", "Behavior",
        ].joined(separator: "")) as! NSObject.Type
        let behaviorWithType = behaviorClass.method(
            for: NSSelectorFromString(selector),
        )!
        let castedBehaviorWithType = unsafeBitCast(
            behaviorWithType,
            to: (@convention(c) (Any?, Selector, Any?) -> NSObject).self,
        )
        return castedBehaviorWithType(
            behaviorClass,
            NSSelectorFromString(selector),
            type,
        )
    }
}
