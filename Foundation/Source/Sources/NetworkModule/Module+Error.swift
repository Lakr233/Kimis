//
//  Network+NMError.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/7.
//

import Foundation

public struct NMError: Codable {
    public let error: ErrorMessage

    public var errorMessage: String {
        if let reason = error.info?.reason {
            return reason
        }
        return error.message
    }

    public struct ErrorMessage: Codable {
        public let id: String
        public let code: String
        public let kind: String
        public let message: String
        public let info: ErrorInfo?

        public struct ErrorInfo: Codable {
            public let param: String
            public let reason: String
        }
    }
}
