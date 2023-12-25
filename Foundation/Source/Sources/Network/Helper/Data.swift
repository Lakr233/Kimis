//
//  Data.swift
//
//
//  Created by Lakr Aream on 2023/1/11.
//

import Foundation

extension Data {
    mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        } else {
            assertionFailure("\(#function) is not designed to handle unknown data")
        }
    }
}
