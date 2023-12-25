//
//  Reminder.swift
//
//
//  Created by QAQ on 2023/3/1.
//
import Foundation
import Network
import XCTest

extension SourceTest {
    func checkNetworkEndpointMetadata(network: Network) {
        var brokenEndpoint: [String] = []
        for endpoint in Network.RequestTarget.allCases {
            if let info = network.endpointInfo[endpoint] {
                print(
                    """
                    [+] validated endpoint \(endpoint.rawValue): \(info.method.rawValue) -> \(info.path)
                    """
                )
            } else {
                brokenEndpoint.append(endpoint.rawValue)
            }
        }
        for item in brokenEndpoint {
            XCTFail("endpoint \(item) failed to check test assignments")
        }
    }

    func checkNetworkEndpointTestCasesFullFilled() {
        var brokenEndpoint: [String] = []
        for item in Network.RequestTarget.allCases {
            if let testCase = item.underlyingTestCase {
                print("[+] endpoint \(item.rawValue) assigned to \(testCase)")
            } else {
                brokenEndpoint.append(item.rawValue)
            }
        }
        for item in brokenEndpoint {
            XCTFail("endpoint \(item) failed to check test assignments")
        }
    }
}

private extension Network.RequestTarget {
    var underlyingTestCase: Any? {
        switch self {
        case .meta: SourceTest.test_200_api_instance.self
        case .emojis: SourceTest.test_200_api_instance.self

        case .account_i: SourceTest.test_201_api_user.self

        case .i_favorites: SourceTest.test_202_api_i_favorites.self
        case .i_notification: SourceTest.test_204_api_i_notification.self

        case .following_create: SourceTest.test_203_api_following.self
        case .following_delete: SourceTest.test_203_api_following.self
        case .following_requests_accept: SourceTest.test_203_api_following.self
        case .following_requests_reject: SourceTest.test_203_api_following.self
        case .following_requests_cancel: SourceTest.test_203_api_following.self
        case .following_invalidate: SourceTest.test_203_api_following.self

        case .users: SourceTest.test_203_api_following.self
        case .users_report_abuse: SourceTest.test_215_report_abuse.self
        case .user_show: SourceTest.test_203_api_following.self
        case .users_followers: SourceTest.test_203_api_following.self
        case .users_following: SourceTest.test_203_api_following.self

        case .user_notes: SourceTest.test_205_api_user.self

        case .blocking_create: SourceTest.test_206_api_block.self
        case .blocking_delete: SourceTest.test_206_api_block.self

        case .notes_create: SourceTest.test_207_notes_create_delete.self
        case .notes_delete: SourceTest.test_207_notes_create_delete.self

        case .notes_show: SourceTest.test_208_notes_status.self
        case .notes_state: SourceTest.test_208_notes_status.self

        case .notes_reactions: SourceTest.test_208_notes_status.self
        case .notes_reactions_create: SourceTest.test_208_notes_status.self
        case .notes_reactions_delete: SourceTest.test_208_notes_status.self
        case .notes_favorites_create: SourceTest.test_208_notes_status.self
        case .notes_favorites_delete: SourceTest.test_208_notes_status.self

        case .notes_timeline: SourceTest.test_209_timeline.self
        case .notes_global_timeline: SourceTest.test_209_timeline.self
        case .notes_hybrid_timeline: SourceTest.test_209_timeline.self
        case .notes_local_timeline: SourceTest.test_209_timeline.self

        case .notes_replies: SourceTest.test_210_notes_replies.self
        case .notes_search_by_tag: SourceTest.test_211_notes_search.self
        case .notes_polls_vote: SourceTest.test_212_notes_polls_vote.self
        case .notes_search: SourceTest.test_211_notes_search.self

        case .hashtags_trend: SourceTest.test_213_hashtag_trand.self

        case .drive_files: SourceTest.test_214_drive_file.self
        case .drive_files_create: SourceTest.test_214_drive_file.self
        case .drive_files_update: SourceTest.test_214_drive_file.self

//        @unknown default: return nil
        }
    }
}
