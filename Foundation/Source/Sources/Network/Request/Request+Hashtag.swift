//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/27.
//

import Foundation
import NetworkModule

public extension Network {
    func requestForHashtagsTrending() -> [MKTrend]? {
        let request = prepareRequest(for: .hashtags_trend)
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return decodeRequest(with: responseData)
    }
}

public extension Network {
    func requestForHashtagsNotes(tag: String, limit: Int = 20, untilId: String?) -> NoteFetchResult<[NMNote]>? {
        var tag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if tag.hasPrefix("#") { tag.removeFirst() }

        var request = prepareRequest(for: .notes_search_by_tag)
        injectBodyForPost(for: &request, with: [
            "limit": limit,
            "tag": tag,
        ])
        if let untilId {
            injectBodyForPost(for: &request, with: [
                "untilId": untilId,
            ])
        }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else {
            return nil
        }
        return decodeResponseAndLookForNotes(jsonData: responseData)
    }
}
