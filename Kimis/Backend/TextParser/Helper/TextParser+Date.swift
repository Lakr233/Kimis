//
//  TextParser+Date.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import Foundation
import UIKit

extension TextParser {
    func compileDateRelative(date: Date) -> String {
        dateFormatters.relative.localizedString(for: date, relativeTo: Date())
    }

    func compileDateAbsolute(date: Date) -> String {
        dateFormatters.absolute.string(from: date)
    }

    func compile(date: Date) -> String {
        let build = [
            compileDateAbsolute(date: date),
            compileDateRelative(date: date),
        ]
        return build
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
