//
//  Localization.swift
//  Kimis
//
//  Created by Star on 2025/10/8.
//

import Foundation

public enum L10n {
    public struct Key: ExpressibleByStringLiteral, Hashable, Sendable {
        public let raw: String
        public init(_ raw: String) { self.raw = raw }
        public init(stringLiteral value: String) { raw = value }
    }

    public enum Common {
        public static let welcome: Key = "welcome_message"
        public static let error: Key = "error_occurred"
        // ... 其他通用键
    }

    /// 单一入口：支持格式化参数与 iOS 14/15 双栈
    @inline(__always)
    public static func text(_ key: Key,
                            table: String? = nil,
                            _ args: CVarArg...) -> String
    {
        let tableName = table
        let bundle = Bundle.main

        let format: String = if #available(iOS 15.0, *) {
            // 注意：此处用的是变量 key.raw，**不指望它被提取**；
            // 提取交给锚点文件解决。
            if let tableName {
                String(localized: .init(key.raw),
                       table: tableName,
                       bundle: bundle)
            } else {
                String(localized: .init(key.raw),
                       bundle: bundle)
            }
        } else {
            bundle.localizedString(forKey: key.raw,
                                   value: nil,
                                   table: tableName)
        }

        guard args.isEmpty == false else { return format }
        return String(format: format, locale: .current, arguments: args)
    }
}

private extension L10n {
    static func text(_ key: Key, _ table: String?, arguments: [CVarArg]) -> String {
        text(key, table: table, arguments)
    }
}
