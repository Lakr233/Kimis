//
//  Configuration.swift
//  mTale
//
//  Created by Lakr Aream on 2022/3/31.
//

import Foundation

class AppConfig {
    static let current = AppConfig()
    private init() {}

    @UserDefault(key: "wiki.qaq.introduction.completed", defaultValue: false)
    var introductionCompleted: Bool

    @UserDefault(key: "wiki.qaq.fontSize", defaultValue: 16)
    var defaultNoteFontSize: Int {
        didSet {
            if defaultNoteFontSize < 8 { defaultNoteFontSize = 8 }
            if defaultNoteFontSize > 24 { defaultNoteFontSize = 24 }
        }
    }

    @UserDefault(key: "wiki.qaq.accentColor.light", defaultValue: "")
    var accentColorLight: String

    @UserDefault(key: "wiki.qaq.accentColor.dark", defaultValue: "")
    var accentColorDark: String
}
