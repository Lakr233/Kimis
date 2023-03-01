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
        case .meta: return SourceTest.test_200_api_instance.self
        case .emojis: return SourceTest.test_200_api_instance.self

        case .account_i: return SourceTest.test_201_api_user.self

        case .i_favorites: return SourceTest.test_202_api_i_favorites.self
        case .i_notification: return SourceTest.test_203_api_i_notification.self

        case .following_create: return SourceTest.test_204_api_following.self
        case .following_delete: return SourceTest.test_204_api_following.self
        case .following_requests_accept: return SourceTest.test_204_api_following.self
        case .following_requests_reject: return SourceTest.test_204_api_following.self
        case .following_requests_cancel: return SourceTest.test_204_api_following.self
        case .following_invalidate: return SourceTest.test_204_api_following.self

        case .users: return SourceTest.test_204_api_following.self
        case .user_show: return SourceTest.test_204_api_following.self
        case .users_followers: return SourceTest.test_204_api_following.self
        case .users_following: return SourceTest.test_204_api_following.self

        case .user_notes: return SourceTest.test_205_api_user.self

        case .blocking_create: return SourceTest.test_206_api_block.self
        case .blocking_delete: return SourceTest.test_206_api_block.self

        case .notes_create: return SourceTest.test_207_notes_create_delete.self
        case .notes_delete: return SourceTest.test_207_notes_create_delete.self

        case .notes_show: return SourceTest.test_208_notes_status.self
        case .notes_state: return SourceTest.test_208_notes_status.self

        case .notes_reactions: return SourceTest.test_208_notes_status.self
        case .notes_reactions_create: return SourceTest.test_208_notes_status.self
        case .notes_reactions_delete: return SourceTest.test_208_notes_status.self
        case .notes_favorites_create: return SourceTest.test_208_notes_status.self
        case .notes_favorites_delete: return SourceTest.test_208_notes_status.self

        case .notes_timeline: return SourceTest.test_209_timeline.self
        case .notes_global_timeline: return SourceTest.test_209_timeline.self
        case .notes_hybrid_timeline: return SourceTest.test_209_timeline.self
        case .notes_local_timeline: return SourceTest.test_209_timeline.self

        case .notes_replies: return SourceTest.test_210_notes_replies.self
        case .notes_search_by_tag: return SourceTest.test_211_notes_search.self
        case .notes_polls_vote: return SourceTest.test_212_notes_polls_vote.self
        case .notes_search: return SourceTest.test_211_notes_search.self

        case .hashtags_trend: return SourceTest.test_212_hashtag_trand.self

        case .drive_files: return SourceTest.test_213_drive_file.self
        case .drive_files_create: return SourceTest.test_213_drive_file.self
        case .drive_files_update: return SourceTest.test_213_drive_file.self

//        @unknown default: return nil
        }
    }
}
