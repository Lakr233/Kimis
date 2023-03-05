//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation

public extension Network {
    func searchNoteWithUserDetailed(data: Data?) -> NoteFetchResult<NMUserDetails?> {
        guard let data,
              let object = try? decoder.decode(NMUserDetails.self, from: data)
        else { return .init(result: nil, extracted: []) }

        var extracted: [NMNote] = []
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let pinnedNotes = object["pinnedNotes"],
           let pinnedNotesData = try? JSONSerialization.data(withJSONObject: pinnedNotes)
        {
            let ans = decodeResponseAndLookForNotes(jsonData: pinnedNotesData)
            extracted = ans.result + ans.extracted
        }

        return .init(result: object, extracted: extracted)
    }

    func requestForUserDetails(userIdOrName userDescriptor: String) -> NoteFetchResult<NMUserDetails?> {
        var request = prepareRequest(for: .user_show)
        if userDescriptor.hasPrefix("@") {
            // use as username
            var username: String?
            var host: String?
            var builder = userDescriptor
            builder.removeFirst()
            if builder.contains("@") {
                let comps = builder.components(separatedBy: "@")
                assert(comps.count == 2)
                username = comps.first
                host = comps.last
            } else {
                username = builder
            }
            injectBodyForPost(for: &request, with: ["username": username ?? "?"])
            if let host {
                injectBodyForPost(for: &request, with: ["host": host])
            }
        } else {
            // use as userid
            injectBodyForPost(for: &request, with: ["userId": userDescriptor])
        }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return searchNoteWithUserDetailed(data: responseData)
    }

    enum UserNoteFetchType: CaseIterable {
        case notes
        case replies
        case attachments
    }

    func requestForUserNotes(userId: String, type: UserNoteFetchType, sinceId: String? = nil, untilId: String? = nil, sinceDate: Date? = nil, untilDate: Date? = nil) -> NoteFetchResult<[NMNote]> {
        var request = prepareRequest(for: .user_notes)
        injectBodyForPost(for: &request, with: ["userId": userId])
        switch type {
        case .notes:
            injectBodyForPost(for: &request, with: ["includeReplies": false])
        case .replies:
            injectBodyForPost(for: &request, with: ["includeReplies": true])
        case .attachments:
            injectBodyForPost(for: &request, with: ["withFiles": true])
        }
        if let sinceDate {
            injectBodyForPost(for: &request, with: [
                "sinceDate": String(Int(sinceDate.timeIntervalSince1970)),
            ])
        }
        if let untilDate {
            injectBodyForPost(for: &request, with: [
                "untilDate": String(Int(untilDate.timeIntervalSince1970)),
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

        return decodeResponseAndLookForNotes(jsonData: responseData)
    }

    func requestForUserFavorite(limit: Int = 20, untilId: String? = nil, sinceId: String? = nil) -> NoteFetchResult<[NMNote]> {
        var request = prepareRequest(for: .i_favorites)
        injectBodyForPost(for: &request, with: ["limit": limit])
        if let untilId {
            injectBodyForPost(for: &request, with: ["untilId": untilId])
        }
        if let sinceId {
            injectBodyForPost(for: &request, with: ["sinceId": sinceId])
        }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else {
            return .init(result: [], extracted: [])
        }

        return decodeResponseAndLookForNotes(jsonData: responseData, noteArrayKeyPath: ["note"])
    }

    func requestUserNotifications(limit: Int = 20, untilId: String? = nil, markAsRead: Bool = true) -> NoteFetchResult<[NMNotification]> {
        var request = prepareRequest(for: .i_notification)
        injectBodyForPost(for: &request, with: [
            "limit": limit,
            "markAsRead": markAsRead,
        ])
        if let untilId {
            injectBodyForPost(for: &request, with: ["untilId": untilId])
        }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else { return .init(result: [], extracted: []) }
        let extracted = decodeResponseAndLookForNotes(jsonData: responseData, noteArrayKeyPath: ["note"])
        var notifications: [NMNotification] = []
        let preflight = try? JSONSerialization.jsonObject(with: responseData) as? [[String: Any]]
        for each in preflight ?? [] {
            guard let data = try? JSONSerialization.data(withJSONObject: each),
                  let notification: NMNotification = decodeRequest(with: data)
            else {
                print("[*] failed to decode a notification, ignoring!")
                continue
            }
            notifications.append(notification)
        }
        return .init(result: notifications, extracted: extracted.result + extracted.extracted)
    }

    enum UsersOriginType: String {
        case combined
        case local
        case remote
    }

    enum UsersSortType: String {
        case followerAscending = "+follower"
        case followerDescending = "-follower"
        case createdAtAscending = "+createdAt"
        case createdAtDescending = "-createdAt"
        case updatedAtAscending = "+updatedAt"
        case updatedAtDescending = "-updatedAt"
    }

    enum UsersStateType: String {
        case all
        case admin
        case moderator
        case adminOrModerator
        case alive
    }

    func requestForUsers(limit: Int = 20, offset: Int? = nil, origin: UsersOriginType = .combined, sort: UsersSortType = .createdAtDescending, state: UsersStateType? = nil, hostname: String? = nil) -> NoteFetchResult<[NMUserDetails]> {
        var request = prepareRequest(for: .users)
        injectBodyForPost(for: &request, with: [
            "limit": limit,
            "origin": origin.rawValue,
            "sort": sort.rawValue,
        ])
        if let offset { injectBodyForPost(for: &request, with: ["offset": offset]) }
        if let state { injectBodyForPost(for: &request, with: ["state": state.rawValue]) }
        if let hostname { injectBodyForPost(for: &request, with: ["hostname": hostname]) }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }

        var answer: [NMUserDetails] = []
        var extractedNotes: [NMNote] = []
        if let data = responseData,
           let objects = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        {
            for item in objects {
                guard let data = try? JSONSerialization.data(withJSONObject: item) else {
                    continue
                }
                if let pinnedNotes = item["pinnedNotes"],
                   let pinnedNotesData = try? JSONSerialization.data(withJSONObject: pinnedNotes)
                {
                    let ans = decodeResponseAndLookForNotes(jsonData: pinnedNotesData)
                    extractedNotes = ans.result + ans.extracted
                }
                if let user: NMUserDetails = decodeRequest(with: data) {
                    answer.append(user)
                    continue
                }
            }
        }

        return .init(result: answer, extracted: extractedNotes)
    }

    func requestBlockUser(userId: String) -> NoteFetchResult<NMUserDetails?> {
        var request = prepareRequest(for: .blocking_create)
        injectBodyForPost(for: &request, with: ["userId": userId])
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return searchNoteWithUserDetailed(data: responseData)
    }

    func requestUnblockUser(userId: String) -> NoteFetchResult<NMUserDetails?> {
        var request = prepareRequest(for: .blocking_delete)
        injectBodyForPost(for: &request, with: ["userId": userId])
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return searchNoteWithUserDetailed(data: responseData)
    }

    func requestForUserFollowers(userId: String, limit: Int = 20, untilId: String? = nil, sinceId: String? = nil) -> [NMFollowRecord] {
        var request = prepareRequest(for: .users_followers)
        injectBodyForPost(for: &request, with: ["userId": userId])
        injectBodyForPost(for: &request, with: ["limit": limit])
        if let untilId { injectBodyForPost(for: &request, with: ["untilId": untilId]) }
        if let sinceId { injectBodyForPost(for: &request, with: ["sinceId": sinceId]) }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return decodeRequest(with: responseData) ?? []
    }

    func requestForUserFollowing(userId: String, limit: Int = 20, untilId: String? = nil, sinceId: String? = nil) -> [NMFollowRecord] {
        var request = prepareRequest(for: .users_following)
        injectBodyForPost(for: &request, with: ["userId": userId])
        injectBodyForPost(for: &request, with: ["limit": limit])
        if let untilId { injectBodyForPost(for: &request, with: ["untilId": untilId]) }
        if let sinceId { injectBodyForPost(for: &request, with: ["sinceId": sinceId]) }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return decodeRequest(with: responseData) ?? []
    }

    func requestForReportAbuse(userId: String, comment: String) {
        var request = prepareRequest(for: .users_report_abuse)
        injectBodyForPost(for: &request, with: ["userId": userId])
        injectBodyForPost(for: &request, with: ["comment": comment])
        makeRequest(with: request) { _ in }
    }
}
