//
//  UserDefault.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/6.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

@propertyWrapper
public struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var storage: UserDefaults = .standard

    public init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    public var wrappedValue: Value {
        get {
            if let value = storage.value(forKey: key) as? Value {
                return value
            } else {
                storage.setValue(defaultValue, forKey: key)
                return defaultValue
            }
        }
        set {
            storage.setValue(newValue, forKey: key)
            #if DEBUG
                storage.synchronize()
                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            #endif
        }
    }
}

public extension UserDefault where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}
