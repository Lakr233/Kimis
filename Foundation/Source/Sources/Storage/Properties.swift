//
//  Properties.swift
//
//
//  Created by Lakr Aream on 2022/11/15.
//

import Combine
import Foundation

@propertyWrapper
public class PropertyStorage<T: Codable> {
    public init(key: Properties.Key, defaultValue: T, storage: Properties, notify: Notification.Name? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
        self.notify = notify
    }

    let key: Properties.Key
    let defaultValue: T
    let storage: Properties
    let notify: Notification.Name?

    var cache: T?
    let lock = NSLock()

    public var wrappedValue: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            if let cache { return cache }
            let value = storage.readProperty(fromKey: key, defaultValue: defaultValue)
            cache = value
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            cache = newValue
            storage.setProperty(toKey: key, withObject: newValue)
            guard let notify else { return }
            DispatchQueue.global().async {
                if let object = newValue as? (any Identifiable) {
                    NotificationCenter.default.post(name: notify, object: object.id)
                } else {
                    NotificationCenter.default.post(name: notify, object: nil)
                }
            }
        }
    }
}

public class Properties {
    let writeQueue = DispatchQueue(label: "wiki.qaq.properties.write.\(UUID().uuidString)")

    let storeLocation: URL

    let storeSubject = PassthroughSubject<(Codable, URL), Never>()
    var cancellable = Set<AnyCancellable>()

    public init(storeLocation: URL) {
        self.storeLocation = storeLocation

        if let data = try? Data(contentsOf: storeLocation) {
            if let object = try? decoder.decode([Key: Data].self, from: data) {
                properties = object
            }
        }

        storeSubject
            .throttle(for: .seconds(0.25), scheduler: DispatchQueue.global(), latest: true)
            .sink { object, target in
                do {
                    let data = try encoder.encode(object)
                    try data.write(to: target)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &cancellable)
    }

    public enum Key: String, Codable {
        case userProfile
        case instanceProfile
        case instanceEmoji

        case timelineEndpoint
        case timelineNode
        case timelineIR

        case bookmark

        case notification
        case notificationRead
        case notificaitonPosted

        case recentEmoji
        case focus
    }

    private let propertyLock = NSLock()
    private var properties: [Key: Data] = [:] {
        didSet {
            let list = properties
            let target = storeLocation
            storeSubject.send((list, target))
        }
    }

    public func setProperty(toKey key: Key, withObject object: some Codable) {
        propertyLock.lock()
        defer { propertyLock.unlock() }
        guard let data = try? encoder.encode(object) else {
            properties.removeValue(forKey: key)
            return
        }
        properties[key] = data
    }

    public func readProperty<T: Codable>(fromKey key: Key, defaultValue: T) -> T {
        propertyLock.lock()
        defer { propertyLock.unlock() }
        if let data = properties[key] {
            if let object = try? decoder.decode(T.self, from: data) {
                return object
            } else {
                return defaultValue
            }
        } else {
            return defaultValue
        }
    }
}
