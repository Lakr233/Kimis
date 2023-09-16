//
//  CodableDefault.swift
//  Chromatic
//
//  Created by Lakr Aream on 2022/3/31.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

private let encoder = PropertyListEncoder()
private let decoder = PropertyListDecoder()

@propertyWrapper
public struct CodableDefault<Value: Codable> {
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
            if let read = storage.value(forKey: key) as? Data,
               let object = try? decoder.decode(Value.self, from: read)
            {
                return object
            }
            return defaultValue
        }
        set {
            do {
                let data = try encoder.encode(newValue)
                storage.setValue(data, forKey: key)
                return
            } catch {
                print("[E] CodableDefault \(#function) \(error.localizedDescription)")
            }
            print("[*] removing this value at \(key)")
            storage.setValue(nil, forKey: key)
        }
    }
}
