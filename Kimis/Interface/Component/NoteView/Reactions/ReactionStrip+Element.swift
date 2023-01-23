//
//  ReactionStrip+Element.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import Foundation

extension ReactionStrip {
    struct Element: Hashable, Equatable {
        let text: String?
        let url: URL?
        let count: Int
        let highlight: Bool

        var validated: Bool {
            if text == nil { return url != nil }
            else { return url == nil }
        }
    }
}
