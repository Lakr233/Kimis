//
//  String.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/1.
//

import UIKit

public extension String {
    func sha256() -> String {
        if let stringData = data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
}
