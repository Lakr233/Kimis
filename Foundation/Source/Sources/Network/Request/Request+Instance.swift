//
//  Request+Instance.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation

public extension Network {
    func requestForInstanceInfo() -> NMInstance? {
        let request = prepareRequest(for: .meta)
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return decodeRequest(with: responseData)
    }

    func requestForEmojis() -> [NMEmoji]? {
        let request = prepareRequest(for: .emojis)
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let data = responseData else { return nil }
        guard let objects = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let emojis = objects["emojis"] as? [Any]
        else { return nil }

        var result = [NMEmoji]()
        for item in emojis {
            guard let itemData = try? JSONSerialization.data(withJSONObject: item),
                  let emoji: NMEmoji = decodeRequest(with: itemData)
            else { continue }
            result.append(emoji)
        }
        return result
    }
}
