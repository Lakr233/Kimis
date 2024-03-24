//
//  SourceTest.swift
//
//
//  Created by QAQ on 2023/3/1.
//

import Foundation
import Network
import Source
import XCTest

let temp = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("wiki.qaq.Kimis.unit.test.\(UUID().uuidString)")

let testAccount = "test"
let testPassword = "test"

var source: Source!

class SourceTest: XCTestCase {
    // MARK: - Set Up

    override class func setUp() {
        super.setUp()
        print("[+] begin login challenge")
        guard let _source = loginToTestServer(
            host: "127.0.0.1",
            port: 3555,
            secured: false,
            username: testAccount,
            password: testPassword,
            store: temp
        ) else {
            XCTFail("login failed")
            return
        }
        let recipe = _source.receipt
        print("[+] test login success")
        print("    \(recipe.challenge)")
        print("    \(recipe.universalIdentifier)")
        print("    \(recipe.token)")

        print("[+] Source object created \(_source)")
        source = _source
    }

    // MARK: Set Up -

    // MARK: 0xx -> Test Environment Setup Condition

    func test_000_login() {
        XCTAssertNotNil(source)
    }

    // MARK: 1xx -> Test Constant

    func test_100_metadata() {
        checkNetworkEndpointMetadata(network: Network(base: URL(fileURLWithPath: "/"), credential: ""))
//        checkNetworkEndpointTestCasesFullFilled()
    }

    // MARK: xxx -> Test Anything

    func test_200_api_instance() {
        checkApi_InstanceMetadata()
    }

    func test_201_api_user() {
        checkApi_AccountI()
    }

    func test_202_api_i_favorites() {
        checkApi_Favorite()
    }

    func test_203_api_following() {
        checkApi_Following()
    }

    func test_204_api_i_notification() {
        checkApi_Notification()
    }

    func test_205_api_user() {
        checkApi_UserNotes()
    }

    func test_206_api_block() {
        checkApi_UserBlock()
    }

    func test_207_notes_create_delete() {
        checkApi_NotesCreateAndDelete()
    }

    func test_208_notes_status() {
        checkApi_NotesStatus()
    }

    func test_209_timeline() {
        checkApi_Timeline()
    }

    func test_210_notes_replies() {
        checkApi_NotesReplies()
    }

    func test_211_notes_search() {
        checkApi_NotesSearch()
    }

    func test_212_notes_polls_vote() {
        checkApi_NotesPollVote()
    }

    func test_213_hashtag_trand() {
        checkApi_Trend()
    }

    func test_214_drive_file() {
        checkApi_DriveFile()
    }

    func test_215_report_abuse() {
        checkApi_UserReportAbuse()
    }

    // MARK: - Tear Down

    override class func tearDown() {
        super.tearDown()
        print("[+] tearing down the test case...")
        source.destroy()
        XCTAssert(source.cancellable.isEmpty)
        source = nil
        try? FileManager.default.removeItem(at: temp)
    }

    // MARK: Tear Down -
}
