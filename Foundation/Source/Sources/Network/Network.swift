import Combine
import Foundation

@_exported import NetworkModule

/*

 We are not providing http support due to security issue.
 https://github.com/misskey-dev/misskey/issues/6583

 */

public class Network {
    public let base: URL
    public internal(set) var credential: String

    public let errorMessage: PassthroughSubject<String, Never> = .init()

    public init(base host: URL, credential secret: String) {
        base = host
        credential = secret
    }

    public func destroy() {
        print("[*] \(#function) is removing credential")
        credential = ""
    }

    public enum RequestTarget: String, CaseIterable {
        case meta
        case emojis

        case account_i

        case i_favorites
        case i_notification

        case following_create
        case following_delete
        case following_requests_accept
        case following_requests_reject
        case following_requests_cancel
        case following_invalidate

        case users

        case user_show
        case user_notes
        case users_followers
        case users_following
        case blocking_create
        case blocking_delete

        case notes_create
        case notes_delete

        case notes_show
        case notes_state
        case notes_timeline
        case notes_global_timeline
        case notes_hybrid_timeline
        case notes_local_timeline
        case notes_reactions
        case notes_reactions_create
        case notes_reactions_delete
        case notes_replies
        case notes_search_by_tag
        case notes_polls_vote
        case notes_favorites_create
        case notes_favorites_delete
        case notes_search

        case hashtags_trend

        case drive_files
        case drive_files_create
        case drive_files_update
    }

    public enum Method: String {
        case undefined = "UNDEFINED"

        case post = "POST"
        case get = "GET"
        case trace = "TRACE"
        case delete = "DELETE"
        case put = "PUT"
        case patch = "PATCH"
    }

    public struct EndpointInfo {
        public var path: String
        public var method: Method
    }

    public let endpointInfo: [RequestTarget: EndpointInfo] = [
        // MARK: - META

        .meta: .init(path: "/meta", method: .post),
        .emojis: .init(path: "/emojis", method: .post),

        // MARK: - ACCOUNT

        .account_i: .init(path: "/i", method: .post),

        .i_favorites: .init(path: "/i/favorites", method: .post),
        .i_notification: .init(path: "/i/notifications", method: .post),

        // MARK: - USER

        .users: .init(path: "/users", method: .post),
        .user_show: .init(path: "/users/show", method: .post),
        .user_notes: .init(path: "/users/notes", method: .post),
        .users_followers: .init(path: "/users/followers", method: .post),
        .users_following: .init(path: "/users/following", method: .post),

        .blocking_create: .init(path: "blocking/create", method: .post),
        .blocking_delete: .init(path: "blocking/delete", method: .post),

        // MARK: - FOLLOWING

        .following_create: .init(path: "/following/create", method: .post),
        .following_delete: .init(path: "/following/delete", method: .post),
        .following_requests_accept: .init(path: "/following/requests/accept", method: .post),
        .following_requests_reject: .init(path: "/following/requests/reject", method: .post),
        .following_requests_cancel: .init(path: "/following/requests/cancel", method: .post),
        .following_invalidate: .init(path: "/following/invalidate", method: .post),

        // MARK: - NOTES

        .notes_create: .init(path: "/notes/create", method: .post),
        .notes_delete: .init(path: "/notes/delete", method: .post),
        .notes_show: .init(path: "/notes/show", method: .post),
        .notes_state: .init(path: "/notes/state", method: .post),
        .notes_timeline: .init(path: "/notes/timeline", method: .post),
        .notes_global_timeline: .init(path: "/notes/global-timeline", method: .post),
        .notes_hybrid_timeline: .init(path: "/notes/hybrid-timeline", method: .post),
        .notes_local_timeline: .init(path: "/notes/local-timeline", method: .post),
        .notes_reactions: .init(path: "/notes/reactions", method: .post),
        .notes_reactions_create: .init(path: "/notes/reactions/create", method: .post),
        .notes_reactions_delete: .init(path: "/notes/reactions/delete", method: .post),
        .notes_replies: .init(path: "/notes/replies", method: .post),
        .notes_search_by_tag: .init(path: "/notes/search-by-tag", method: .post),
        .notes_polls_vote: .init(path: "/notes/polls/vote", method: .post),
        .notes_favorites_create: .init(path: "/notes/favorites/create", method: .post),
        .notes_favorites_delete: .init(path: "/notes/favorites/delete", method: .post),
        .notes_search: .init(path: "/notes/search", method: .post),

        // MARK: - HASHTAG

        .hashtags_trend: .init(path: "/hashtags/trend", method: .post),

        // MARK: - DRIVE

        .drive_files: .init(path: "/drive/files", method: .post),
        .drive_files_create: .init(path: "drive/files/create", method: .post),
        .drive_files_update: .init(path: "drive/files/update", method: .post),
    ]
}

public extension Network {
    static let mutedErrorCodes: Set<URLError.Code> = [
        .timedOut,
    ]
}

internal var decoder = JSONDecoder()
internal var encoder = JSONEncoder()

extension Network {
    func obtainEndpointInfo(for target: RequestTarget) -> EndpointInfo {
        guard let info = endpointInfo[target] else {
            return .init(path: "/unavailable", method: .undefined)
        }
        return info
    }

    func prepareRequest(for target: RequestTarget) -> URLRequest {
        assert(!Thread.isMainThread)
        let info = obtainEndpointInfo(for: target)
        let url = base
            .appendingPathComponent("api")
            .appendingPathComponent(info.path)
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 8
        )
        request.httpMethod = info.method.rawValue
        injectBodyForPost(for: &request, with: ["i": credential])
        return request
    }

    func injectBodyForPost(for request: inout URLRequest, with dic: [String: Any]) {
        assert(request.httpMethod == "POST") // only http post can ship body

        let origBody = request.httpBody ?? "{}".data(using: .utf8) ?? .init()
        guard var dictionaryBuilder = try? JSONSerialization
            .jsonObject(with: origBody, options: .allowFragments)
            as? [String: Any?]
        else {
            assertionFailure()
            return
        }

        for (key, value) in dic { dictionaryBuilder[key] = value }
        guard let newData = try? JSONSerialization
            .data(withJSONObject: dictionaryBuilder, options: .fragmentsAllowed)
        else {
            assertionFailure()
            return
        }

        request.httpBody = newData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    func cleaningJsonObjectByDeletingSpecialEmptyKeyValue(
        object: inout [AnyHashable: Any?]
    ) {
        var result = [AnyHashable: Any?]()
        for (key, value) in object {
            guard var value else { continue }
            if let value = value as? String, value.isEmpty { continue }
            if var deep = value as? [AnyHashable: Any?] {
                cleaningJsonObjectByDeletingSpecialEmptyKeyValue(object: &deep)
                value = deep
            }
            result[key] = value
        }
        object = result
    }

    func makeRequest(
        with request: URLRequest,
        with session: URLSession = .shared,
        setTask: (URLSessionDataTask) -> Void = { _ in },
        completion: @escaping (Data) -> Void
    ) {
        var request = request
        if request.httpMethod?.uppercased() == "POST",
           let origJsonData = request.httpBody,
           var object = try? JSONSerialization.jsonObject(
               with: origJsonData,
               options: .fragmentsAllowed
           ) as? [AnyHashable: Any?]
        {
            cleaningJsonObjectByDeletingSpecialEmptyKeyValue(object: &object)
            if let newData = try? JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed) {
                request.httpBody = newData
            }
        }

        let sem = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, _, error in
            defer { sem.signal() }

            if let misskeyError: NMError = self.decodeRequest(with: data) {
                self.errorMessage.send(misskeyError.errorMessage)
            } else if let error {
                if let error = error as? URLError {
                    if !Self.mutedErrorCodes.contains(error.code) {
                        self.errorMessage.send(error.localizedDescription)
                    }
                } else {
                    self.errorMessage.send(error.localizedDescription)
                }
            }

            if let data { completion(data) }
        }
        setTask(task)
        task.resume()
        sem.wait()
    }

    func decodeRequest<T: Codable>(with data: Data?) -> T? {
        guard let responseData = data,
              let object = try? decoder.decode(T.self, from: responseData)
        else {
            return nil
        }
        return object
    }
}
