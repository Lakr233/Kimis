//
//  Enumerator.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/10.
//

import Foundation
import UIKit

extension TextParser {
    typealias ModifyStringBlock = (_ string: NSMutableAttributedString) -> (NSMutableAttributedString?)

    func enumerateModifying(string: NSMutableAttributedString, duringRanges ranges: [NSRange], operating: ModifyStringBlock) {
        var rangeFixup = 0
        var rangeRemapped = ranges
        rangeRemapped.sort { $0.location < $1.location }
        var currentTail = 0
        for range in rangeRemapped {
            let buildRange = NSRange(location: range.location + rangeFixup, length: range.length)
            guard buildRange.location != NSNotFound, buildRange.location >= 0, buildRange.upperBound <= string.length else {
                return
            }
            guard currentTail <= buildRange.location else {
                #if DEBUG
                    print(
                        """
                        [*] CoreTextParser reported overlapping when enumerating over requested range
                            range start: \(buildRange) ... length \(buildRange.length)
                            accept tail: \(currentTail)
                            sub_string of request: \(string.attributedSubstring(from: buildRange).string)
                            request ignored
                        """,
                    )
                #endif
                continue
            }
            guard let subString = string.attributedSubstring(from: buildRange).mutableCopy() as? NSMutableAttributedString else {
                assertionFailure()
                continue
            }
//            #if DEBUG
//                debugPrint("[*] enumerator calling operation on range \(buildRange.location) \(buildRange.length) \(subString.string.components(separatedBy: "\n").joined(separator: " "))")
//            #endif
            let originalString = subString.string
            guard originalString.utf16.count == subString.length else {
                assertionFailure()
                continue
            }
            guard let modifyRequest = operating(subString) else { continue }

            string.deleteCharacters(in: buildRange)
            string.insert(modifyRequest, at: buildRange.location)

            let positionShift = modifyRequest.length - originalString.utf16.count
            rangeFixup += positionShift

            currentTail = buildRange.location + modifyRequest.length
        }
    }

    func checkingResult(withinString string: NSMutableAttributedString, matching target: String) -> [NSRange] {
        var checkingResult = [NSRange]()
        guard let searchString = (string.string as NSString).mutableCopy() as? NSMutableString else {
            return []
        }
        while searchString.length > 0 {
            let result = searchString.range(of: target, options: .backwards)
            if result.location == NSNotFound { break }
            checkingResult.append(result)
            searchString.deleteCharacters(in: result)
        }
        return checkingResult
    }

    func matchWithRegex(
        withinString string: NSMutableAttributedString,
        matching regex: RegEx,
        options: NSRegularExpression.Options = [.anchorsMatchLines],
    ) -> [NSTextCheckingResult] {
        guard let regexObject = try? NSRegularExpression(pattern: regex.rawValue, options: options) else {
            return []
        }
        let metaString = string.string
        guard metaString.utf16.count == string.length else {
            assertionFailure()
            return []
        }

        #if DEBUG
            let begin = Date()
        #endif

        let matchingResult = regexObject.matches(in: metaString, options: [], range: string.full)

        #if DEBUG
            let elapsedTime = abs(begin.timeIntervalSinceNow)
            if elapsedTime * 1000 > 1 {
                print(
                    """
                    [!] regex took too long to match this string
                        \(Int(elapsedTime * 1000))ms \(regex) \(regex.rawValue)
                    >>>
                    \(metaString)
                    <<<
                    """,
                )
            }
        #endif

        return matchingResult
    }

    func regExMatchFull(string: String, regEx: RegEx, options: NSRegularExpression.Options = [.anchorsMatchLines]) -> Bool {
        let nss = NSMutableAttributedString(string: string)
        let matchingResult = matchWithRegex(withinString: nss, matching: regEx, options: options)
        return matchingResult.count == 1
            && matchingResult[0].range == nss.full
    }

    func enumeratedModifyingWithRegex(
        withinString string: NSMutableAttributedString,
        matching regex: RegEx,
        options: NSRegularExpression.Options = [.anchorsMatchLines],
        operating: ModifyStringBlock,
    ) {
        let matchingResult = matchWithRegex(withinString: string, matching: regex, options: options)
        guard !matchingResult.isEmpty else { return }
        enumerateModifying(string: string, duringRanges: matchingResult.map(\.range), operating: operating)
    }
}
