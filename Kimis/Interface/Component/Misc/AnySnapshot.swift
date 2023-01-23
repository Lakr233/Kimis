//
//  AnySnapshot.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/2.
//

import Foundation

protocol AnySnapshot: AnyObject, Identifiable, Equatable, Hashable {
    var id: UUID { get }

    var width: CGFloat { get set }
    var height: CGFloat { get set }

    var renderHint: Any? { get set }

    func invalidate()

    func prepareForRender()
    func afterRender()
    func setRenderHint(renderHint: Any?)
    func render(usingWidth width: CGFloat)
}

extension Notification.Name {
    static let snapshotRendered = Notification.Name(rawValue: "wiki.qaq.AnySnapshot.Render.Update")
}

extension AnySnapshot {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func prepareForRender() {
        invalidate()
    }

    func afterRender() {
        NotificationCenter.default.post(name: .snapshotRendered, object: id)
    }

    func setRenderHint(renderHint: Any?) {
        self.renderHint = renderHint
    }
}
