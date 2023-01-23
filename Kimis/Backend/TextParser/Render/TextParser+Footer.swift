//
//  TextParser+Text.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/3.
//

import Foundation
import UIKit

extension TextParser {
    func compileDateFooter(withDate date: Date) -> NSMutableAttributedString {
        var dateStrings = [String]()
        do {
            let timeFmt = DateFormatter()
            timeFmt.timeStyle = .short
            timeFmt.string(from: date)
            dateStrings.append(timeFmt.string(from: date))
        }
        do {
            let dayFmt = DateFormatter()
            dayFmt.dateStyle = .short
            dayFmt.string(from: date)
            dateStrings.append(dayFmt.string(from: date))
        }
        do { dateStrings.append(compileDateRelative(date: date)) }
        let preflight = NSMutableAttributedString(string: dateStrings.joined(separator: " - "))
        preflight.addAttributes([
            .font: getFont(size: size.foot, weight: weight.foot),
        ], range: preflight.full)
        colorize(string: preflight, color: color.secondary)
        return finalize(preflight)
    }

    func compileNoteFooter(withNote note: Note) -> NSMutableAttributedString {
        var strings: [NSMutableAttributedString] = [
            compileDateFooter(withDate: note.date),
        ]
        if note.visibility.lowercased() != "public" {
            strings.append(createRestrictedVisibilityHint(size: size.foot))
        }
        let preflight = connect(strings: strings, separator: " ")
        preflight.addAttributes([
            .font: getFont(size: size.foot, weight: weight.foot),
        ], range: preflight.full)
        colorize(string: preflight, color: color.secondary)
        return finalize(preflight)
    }

    func compileVoteFooter(withPoll vote: Note.Poll) -> NSMutableAttributedString {
        var connectors: [String] = []
        connectors.append(
            "\(vote.multiple ? "Multiple" : "Single") Vote"
        )
        if let expire = vote.expiresAt {
            connectors.append("Expire " + compile(date: expire))
        } else {
            connectors.append("Long Term")
        }
        connectors.append("\(vote.totalVotes) vote(s)")
        let preflight = connect(strings: connectors.map { .init(string: $0) }, separator: " - ")
        preflight.addAttributes([
            .font: getFont(size: size.foot, weight: weight.foot),
        ], range: preflight.full)
        colorize(string: preflight, color: color.secondary)
        return finalize(preflight)
    }
}
