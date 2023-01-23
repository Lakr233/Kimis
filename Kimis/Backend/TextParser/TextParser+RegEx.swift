//
//  TextParser+RegEx.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/16.
//

import Foundation

extension TextParser {
    enum RegEx: String, CaseIterable {
        case username = #"(?<=(^|\s))@([A-Za-z0-9_])+(?=($|\s))"#
        case unifiedUsername = #"(?<=(^|\s))@([A-Za-z0-9_])+?@([A-Za-z0-9\-\.]+)\.([A-Za-z]+)(?=($|\s))"#

        case emoji = #":[A-Za-z0-9._]+:"#
        case hashtag = #"#[\u4E00-\u9FCCA-Za-z0-9\.]+"#
        case repliesMentionPrefix = #"^((@([A-Za-z0-9_])+?@([A-Za-z0-9\-\.]+)\.([A-Za-z]+)) )+"#
        case mail = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}"#
        case link = #"https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}\b([-a-zA-Z0-9@:%_\+.~#?&,//=]*)"#
        case idna = #"(xn--)(--)*[a-z0-9]+[^. ]"#

        case dollarAttribute = #"\$\[.+ .+\]"#

        case markdownAttachment = #"\[([^\]]*?)\]\(([^)]*?)\)"#
        case markdownBold = #"\*\*(.+?)\*\*(?!\*)"#
        case markdownStrikethrough = #"\~\~(.+?)\~\~(?!\~)"#
        case markdownMonospaceInline = #"`.+?`"#
        case markdownMonospaceMultiLine = #"```((.|\n)*?)```"#
        case markdownQuote = #"^>.+$"#
    }
}
