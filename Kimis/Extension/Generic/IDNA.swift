//
//  IDNA.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/3.
//

import Foundation
import IDNA

// force IDNA to load all the mapping data
// before text parser calling it with multiple thread
// and then crash the app

extension AppDelegate {
    static func setupIDNADecoder() {
        assert(!Thread.isMultiThreaded())
        _ = "xn--abc".idnaDecoded
    }
}
