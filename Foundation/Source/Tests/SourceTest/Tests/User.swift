//
//  User.swift
//
//
//  Created by QAQ on 2023/3/1.
//

import Foundation
import Module
import Network
import Source
import XCTest

extension SourceTest {
    func checkApi_AccountI() {
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: "@" + source.receipt.username)
            unwrapOrFail(ans) { _ in }
            unwrapOrFail(ans.result) { item in
                unwrapOrFail(item.id) {
                    XCTAssert(!$0.isEmpty)
                    XCTAssertEqual($0, source.receipt.accountId)
                }
                unwrapOrFail(item.username) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(item.avatarUrl) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(item.createdAt) { XCTAssert(!$0.isEmpty) }
                let userModel = UserProfile.converting(item, defaultHost: "localhost")
                unwrapOrFail(userModel) {
                    XCTAssertEqual($0.userId, source.receipt.accountId)
                    XCTAssert($0.createdAt > Date(timeIntervalSince1970: 100))
                }
            }
        }
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: source.receipt.accountId)
            unwrapOrFail(ans) { _ in }
            unwrapOrFail(ans.result) { item in
                unwrapOrFail(item.id) {
                    XCTAssert(!$0.isEmpty)
                    XCTAssertEqual($0, source.receipt.accountId)
                }
                unwrapOrFail(item.username) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(item.avatarUrl) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(item.createdAt) { XCTAssert(!$0.isEmpty) }
                let userModel = UserProfile.converting(item, defaultHost: "localhost")
                unwrapOrFail(userModel) {
                    XCTAssertEqual($0.userId, source.receipt.accountId)
                    XCTAssert($0.createdAt > Date(timeIntervalSince1970: 100))
                }
            }
        }
    }

    func checkApi_Favorite() {
        dispatchAndWait {
            let ans = source.network.requestForUserFavorite()
            unwrapOrFail(ans) { _ in }
            unwrapOrFail(ans.result) { XCTAssert(!$0.isEmpty) }
        }
    }

    func checkApi_Notification() {
        dispatchAndWait {
            let ans = source.network.requestUserNotifications()
            unwrapOrFail(ans) { _ in }
            unwrapOrFail(ans.result) { XCTAssert(!$0.isEmpty) }
        }
    }

    func checkApi_Following() {
        let userId = source.receipt.accountId
        var user2: UserProfile?
        var user3: UserProfile?
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: "@test2")
            unwrapOrFail(ans.result) {
                user2 = .converting($0, defaultHost: "localhost")
            }
        }
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: "@test3")
            unwrapOrFail(ans.result) {
                user3 = .converting($0, defaultHost: "localhost")
            }
        }
        guard let user2, let user3 else {
            XCTFail("unable to locate test users")
            return
        }
        XCTAssertNotEqual(user2.userId, user3.userId)
        // follow user 2
        dispatchAndWait {
            source.network.requestFollowingCreate(to: user2.userId)
            let ans = source.network.requestForUserFollowing(userId: userId)
            unwrapOrFail(ans) { item in
                var found = false
                item.forEach { record in
                    XCTAssertEqual(record.followerId, userId)
                    if record.followeeId == user2.userId { found = true }
                }
                XCTAssert(found)
            }
        }
        // unfollow user2
        dispatchAndWait {
            source.network.requestFollowingDelete(to: user2.userId)
            let ans = source.network.requestForUserFollowing(userId: userId)
            unwrapOrFail(ans) { item in
                var found = false
                item.forEach { record in
                    XCTAssertEqual(record.followeeId, userId)
                    if record.followeeId == user2.userId { found = true }
                }
                XCTAssert(found == false)
            }
        }
        // check following request to test3
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: user3.userId)
            unwrapOrFail(ans.result) {
                let user3 = UserProfile.converting($0, defaultHost: "localhost")
                unwrapOrFail(user3?.hasPendingFollowRequestFromYou) {
                    XCTAssert($0 == true)
                }
            }
        }
        // invalidate follow request to test3
        dispatchAndWait {
            source.network.requestFollowingRequestCancel(to: user3.userId)
            let ans = source.network.requestForUserDetails(userIdOrName: user3.userId)
            unwrapOrFail(ans.result) {
                let user3 = UserProfile.converting($0, defaultHost: "localhost")
                unwrapOrFail(user3?.hasPendingFollowRequestFromYou) {
                    XCTAssert($0 == false)
                }
            }
        }
        // follow again to test3
        dispatchAndWait {
            source.network.requestFollowingCreate(to: user3.userId)
            let ans = source.network.requestForUserDetails(userIdOrName: user3.userId)
            unwrapOrFail(ans.result) {
                let user3 = UserProfile.converting($0, defaultHost: "localhost")
                unwrapOrFail(user3?.hasPendingFollowRequestFromYou) {
                    XCTAssert($0 == true)
                }
            }
        }
        // check test2's follow request
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: user2.userId)
            unwrapOrFail(ans.result) {
                let user2 = UserProfile.converting($0, defaultHost: "localhost")
                unwrapOrFail(user2?.hasPendingFollowRequestToYou) {
                    XCTAssert($0 == true)
                }
            }
        }
        // reject test2's follow request
        dispatchAndWait {
            source.network.requestFollowingRequestReject(to: user2.userId)
            let ans = source.network.requestForUserFollowers(userId: userId)
            unwrapOrFail(ans) { item in
                var found = false
                item.forEach { record in
                    XCTAssertEqual(record.followeeId, userId)
                    if record.followerId == user2.userId { found = true }
                }
                XCTAssert(found == false)
            }
        }
        // check test3's follow request
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: user3.userId)
            unwrapOrFail(ans.result) {
                let user3 = UserProfile.converting($0, defaultHost: "localhost")
                unwrapOrFail(user3?.hasPendingFollowRequestToYou) {
                    XCTAssert($0 == true)
                }
            }
        }
        // accept test3's follow request
        dispatchAndWait {
            source.network.requestFollowingRequestAccept(to: user3.userId)
            let ans = source.network.requestForUserFollowers(userId: userId)
            unwrapOrFail(ans) { item in
                var found = false
                item.forEach { record in
                    XCTAssertEqual(record.followeeId, userId)
                    if record.followerId == user3.userId { found = true }
                }
                XCTAssert(found)
            }
        }
        // check test3's follow request
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: user3.userId)
            unwrapOrFail(ans.result) {
                let user3 = UserProfile.converting($0, defaultHost: "localhost")
                unwrapOrFail(user3?.hasPendingFollowRequestToYou) {
                    XCTAssert($0 == false)
                }
            }
        }
    }

    func checkApi_UserNotes() {
        let userId = source.receipt.accountId
        for userNoteFetchType in Network.UserNoteFetchType.allCases {
            dispatchAndWait {
                let ans = source.network.requestForUserNotes(userId: userId, type: userNoteFetchType)
                unwrapOrFail(ans.result) { notes in
                    XCTAssert(!notes.isEmpty)
                }
            }
        }
    }

    func checkApi_UserBlock() {
        var user2: UserProfile?
        dispatchAndWait {
            let ans = source.network.requestForUserDetails(userIdOrName: "@test2")
            unwrapOrFail(ans.result) {
                user2 = .converting($0, defaultHost: "localhost")
            }
        }
        guard let user2 else {
            XCTFail("unable to locate test users")
            return
        }
        XCTAssert(!user2.isBlocked)

        // block!
        dispatchAndWait {
            let ans = source.network.requestBlockUser(userId: user2.userId)
            unwrapOrFail(ans)
            unwrapOrFail(ans.result) {
                unwrapOrFail($0.isBlocked) { XCTAssert(!$0) }
            }
        }

        // unblock!
        dispatchAndWait {
            let ans = source.network.requestUnblockUser(userId: user2.userId)
            unwrapOrFail(ans)
            unwrapOrFail(ans.result) {
                unwrapOrFail($0.isBlocked) { XCTAssert(!$0) }
            }
        }
    }
}
