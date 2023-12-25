//
//  Request+Following.swift
//
//
//  Created by Lakr Aream on 2022/11/29.
//

import Foundation
import NetworkModule

public extension Network {
    func requestFollowingCreate(to userId: String) {
        var request = prepareRequest(for: .following_create)
        injectBodyForPost(for: &request, with: ["userId": userId])
        makeRequest(with: request) { _ in }
    }

    func requestFollowingDelete(to userId: String) {
        var request = prepareRequest(for: .following_delete)
        injectBodyForPost(for: &request, with: ["userId": userId])
        makeRequest(with: request) { _ in }
    }

    func requestFollowingRequestAccept(to userId: String) {
        var request = prepareRequest(for: .following_requests_accept)
        injectBodyForPost(for: &request, with: ["userId": userId])
        makeRequest(with: request) { _ in }
    }

    func requestFollowingRequestReject(to userId: String) {
        var request = prepareRequest(for: .following_requests_reject)
        injectBodyForPost(for: &request, with: ["userId": userId])
        makeRequest(with: request) { _ in }
    }

    func requestFollowingRequestCancel(to userId: String) {
        var request = prepareRequest(for: .following_requests_cancel)
        injectBodyForPost(for: &request, with: ["userId": userId])
        makeRequest(with: request) { _ in }
    }

    func requestFollowingInvalidate(to userId: String) {
        var request = prepareRequest(for: .following_invalidate)
        injectBodyForPost(for: &request, with: ["userId": userId])
        makeRequest(with: request) { _ in }
    }
}
