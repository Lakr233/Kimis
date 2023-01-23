//
//  TextParser+IDNA.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/2.
//

import Foundation

extension TextParser {
    func decodingIDNAIfNeeded(modifyingStringInPlace string: NSMutableAttributedString) {
        enumeratedModifyingWithRegex(withinString: string, matching: .idna) { string in
            let meta = string.string
            guard meta.hasPrefix("xn--"), let decode = meta.idnaDecoded, decode != meta else {
                return nil
            }
            return .init(string: decode, attributes: string.attributes)
        }
    }
}
