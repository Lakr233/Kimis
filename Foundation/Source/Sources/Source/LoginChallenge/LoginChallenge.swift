//
//  LoginChallenge.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/24.
//

import Foundation

private let requestPermission = [
    "read:admin",
    "write:admin",

    "read:account",
    "read:blocks",
    "read:channels",
    "read:clip",
    "read:drive",
    "read:favorites",
    "read:federation",
    "read:flash",
    "read:following",
    "read:gallery",
    "read:invite",
    "read:messaging",
    "read:mutes",
    "read:notifications",
    "read:page",
    "read:pages",
    "read:reactions",
    "read:user",

    "write:account",
    "write:blocks",
    "write:channels",
    "write:clip",
    "write:drive",
    "write:favorites",
    "write:flash",
    "write:following",
    "write:gallery",
    "write:invite",
    "write:messaging",
    "write:mutes",
    "write:notes",
    "write:notifications",
    "write:page",
    "write:pages",
    "write:reactions",
    "write:report-abuse",
    "write:user",
    "write:votes",
]
.joined(separator: ",")

public struct LoginChallenge {
    public let requestHost: String
    public let requestURL: URL
    public let requestSession: String
    public let requestRecipeCheck: URLRequest

    public init(requestHost: String, requestURL: URL, requestSession: String, requestRecipeCheck: URLRequest) {
        self.requestHost = requestHost
        self.requestURL = requestURL
        self.requestSession = requestSession
        self.requestRecipeCheck = requestRecipeCheck
    }

    public init?(host: String) {
        let session = "AAA6969A-85A9-49CE-92F3-5815E52B88F5-" + UUID().uuidString
        // let's use a magic here
        // AAA6969A-85A9-49CE-92F3-5815E52B88F5
        // it was generated once in development, and I found it little cute
        // so, if you do the audit and find this uuid, luck was here on my mbp.
        guard let base = URL(string: "https://\(host)"),
              base.scheme == "https"
        else {
            return nil
        }
        requestHost = host
        let endpoint = base
            .appendingPathComponent("miauth")
            .appendingPathComponent(session)
        guard var comps = URLComponents(string: endpoint.absoluteString) else {
            return nil
        }
        comps.queryItems = [
            .init(name: "permission", value: requestPermission),
        ]
        guard let final = comps.url else {
            return nil
        }
        requestURL = final
        requestSession = session
        let receiptURL = base
            .appendingPathComponent("api")
            .appendingPathComponent("miauth")
            .appendingPathComponent(session)
            .appendingPathComponent("check")
        var checkerRequest = URLRequest(
            url: receiptURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10
        )
        checkerRequest.httpMethod = "POST"
        checkerRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        checkerRequest.httpBody = "{}".data(using: .utf8)
        requestRecipeCheck = checkerRequest
    }

    public func check() -> LoginChallengeReceipt? {
        assert(!Thread.isMainThread)

        let sem = DispatchSemaphore(value: 0)

        var apiToken: String?
        var username: String?
        var userId: String?

        URLSession
            .shared
            .dataTask(with: requestRecipeCheck) { data, _, _ in
                defer { sem.signal() }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                      let token = json["token"] as? String,
                      let name = (json["user"] as? [String: Any?])?["username"] as? String,
                      let id = (json["user"] as? [String: Any?])?["id"] as? String
                else {
                    return
                }

                apiToken = token
                username = name
                userId = id
            }
            .resume()

        sem.wait()

        guard let token = apiToken,
              let user = username,
              let id = userId
        else {
            return nil
        }
        return .init(
            accountId: id,
            username: user,
            host: requestHost,
            token: token,
            challenge: requestSession
        )
    }
}
