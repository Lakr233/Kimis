//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/24.
//

import Foundation
import Module
import ModuleBridge
import Network
import Storage

public extension Source {
    class NetworkWrapper {
        weak var ctx: Source?
        internal init(ctx: Source) {
            self.ctx = ctx
        }
    }
}
