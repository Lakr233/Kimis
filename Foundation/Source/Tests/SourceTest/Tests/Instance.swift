//
//  Instance.swift
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
    func checkApi_InstanceMetadata() {
        dispatchAndWait {
            unwrapOrFail(source.network.requestForInstanceInfo()) { info in
                unwrapOrFail(info.uri) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(info.name) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(info.description) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(info.version) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(info.maintainerName) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(info.maintainerEmail) { XCTAssert(!$0.isEmpty) }
                unwrapOrFail(info.features) { XCTAssert(!$0.isEmpty) }
            }
        }
        dispatchAndWait {
            unwrapOrFail(source.network.requestForEmojis()) {
                XCTAssert(!$0.isEmpty)
            }
        }
    }

    func checkApi_Trend() {
        dispatchAndWait {
            let tag = "trending_test"
            let post = NMPost.converting(Post(text: "#\(tag)"))!
            for _ in 0 ... 4 {
                _ = source.network.requestForNoteCreate(with: post, renoteId: nil, replyId: nil)
            }
            sleep(6)
            let ans = source.network.requestForHashtagsTrending()
            unwrapOrFail(ans) {
                XCTAssert(!$0.isEmpty)
                XCTAssert($0.map(\.tag).contains(tag))
            }
        }
    }
}
