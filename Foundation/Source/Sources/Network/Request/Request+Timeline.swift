//
//  Request+Timeline.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation
import SwiftDate

public extension Network {
    /// 请求时间线的数据
    /// - Parameters:
    ///   - endpoint: 时间线类型
    ///   - limit: 一次拉取的数量
    ///   - sinceDate: 从这个时间往后 更新的数据
    ///   - untilDate: 从这个时间往前 更旧的数据
    ///   - sinceId: 从这个帖子往后 更新的数据
    ///   - untilId: 从这个帖子往前 更旧的数据
    /// - Returns: 解析结果
    func requestForUserTimeline(
        using endpoint: String,
        limit: Int,
        sinceDate: Date?,
        untilDate: Date?,
        sinceId: String?,
        untilId: String?
    ) -> NoteFetchResult<[NMNote]> {
        var request: URLRequest
        switch endpoint {
        case "home":
            request = prepareRequest(for: .notes_timeline)
        case "global":
            request = prepareRequest(for: .notes_global_timeline)
        case "hybrid":
            request = prepareRequest(for: .notes_hybrid_timeline)
        case "local":
            request = prepareRequest(for: .notes_local_timeline)
        default:
            #if DEBUG
                fatalError("malformed structure")
            #else
                request = prepareRequest(for: .notes_timeline)
            #endif
        }
        injectBodyForPost(for: &request, with: ["limit": limit])
        if let sinceDate {
            injectBodyForPost(for: &request, with: [
                "sinceDate": Int(sinceDate.timeIntervalSince1970) * 1000,
            ])
        }
        if let untilDate {
            injectBodyForPost(for: &request, with: [
                "untilDate": Int(untilDate.timeIntervalSince1970) * 1000,
            ])
        }
        if let sinceId {
            injectBodyForPost(for: &request, with: ["sinceId": sinceId])
        }
        if let untilId {
            injectBodyForPost(for: &request, with: ["untilId": untilId])
        }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else {
            return .init(result: [], extracted: [])
        }

        let result = decodeResponseAndLookForNotes(jsonData: responseData)

        print("==============================")
        print("[Timeline Fetch Report] (\(result.result.count + result.extracted.count))")
        print("  Request: \(request)")
        print("  Endpoint: \(endpoint)")
        print("  Fetched Timeline: \(result.result.count)")
        print("  Extracted: \(result.extracted.count)")
        print("==============================")

        return result
    }
}
