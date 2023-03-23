//
//  Note.swift
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
    private func canBePosted(post: Post, renoteId: String?) -> Bool {
        let textLimit = source.instance.maxNoteTextLength
        if post.text.count > textLimit { return false }
        if !post.hasContent, renoteId == nil { return false }
        if let poll = post.poll {
            if poll.choices.count < 2 { return false }
            if Set(poll.choices).count != poll.choices.count { return false }
            if poll.choices.contains("") { return false }
        }
        return true
    }

    private func checkApi_NotesCreateAndDelete(withPost post: Post, renote: String?, reply: String?) {
        guard let nmpost = NMPost.converting(post) else {
            XCTFail("can not convert post")
            return
        }
        let ans = source.network.requestForNoteCreate(with: nmpost, renoteId: renote, replyId: reply)
        guard let note = ans?.result else {
            XCTFail("failed to create note")
            return
        }
        defer {
            source.network.requestForNoteDelete(with: note.id)
        }
        if !post.text.isEmpty {
            unwrapOrFail(note.text) { XCTAssertEqual($0, post.text) }
        }
        if let renote {
            unwrapOrFail(note.renoteId) { XCTAssertEqual($0, renote) }
        }
        if let reply {
            unwrapOrFail(note.replyId) { XCTAssertEqual($0, reply) }
        }
        if let cw = post.cw {
            unwrapOrFail(note.cw) { XCTAssertEqual($0, cw) }
        }
        if post.attachments.count > 0 {
            for (idx, _) in post.attachments.enumerated() {
                guard let files = note.files, let fileIds = note.fileIds else {
                    XCTFail("post attachment mismatch")
                    return
                }
                guard files.count > idx, idx >= 0 else {
                    XCTFail("post attachment mismatch")
                    return
                }
                guard fileIds.count > idx, idx >= 0 else {
                    XCTFail("post attachment mismatch")
                    return
                }
                XCTAssert(post.attachments[idx].attachId == fileIds[idx])
                XCTAssert(post.attachments[idx].attachId == files[idx].id)
            }
        }
        if let poll = post.poll {
            unwrapOrFail(note.poll)
            guard let notePoll = Note.converting(note)?.poll else {
                XCTFail("post poll mismatch")
                return
            }
            XCTAssert(poll.multiple == notePoll.multiple)
            XCTAssert(poll.choices == notePoll.choices.map(\.text))
            if let wantExpire = post.poll?.expiresAt {
                guard let hereExpire = notePoll.expiresAt else {
                    XCTFail("post poll mismatch")
                    return
                }
                XCTAssert(abs(hereExpire.timeIntervalSince(wantExpire)) < 5)
            }
        }
    }

    private struct TestPost: Hashable, Equatable {
        let post: Post
        let renote: String?
        let reply: String?
    }

    func checkApi_NotesCreateAndDelete() {
        dispatchAndWait {
            let possiblePost = self.createTestPosts()
            for post in possiblePost where self.canBePosted(post: post.post, renoteId: post.renote) {
                self.checkApi_NotesCreateAndDelete(withPost: post.post, renote: post.renote, reply: post.reply)
            }
        }
    }

    private func createTestPosts() -> [TestPost] {
        let texts: [String] = ["aaa", ""]
        let attachments: [Attachment] = [
            .init(
                attachId: "01GTDT69A79TXBV8H8DPAWQYZ6",
                name: "",
                user: "",
                url: URL(fileURLWithPath: "/"),
                contentType: "",
                contentSize: 0,
                previewBlurHash: nil,
                preferredWidth: nil,
                preferredHeight: nil,
                isSensitive: false
            ),
        ]

        let polls: [Post.Poll] = [
            .init(expiresAt: Date().addingTimeInterval(10_000_000), choices: ["aa", "bb"], multiple: false),
            .init(expiresAt: nil, choices: ["cc", "dd"], multiple: true),
        ]

        let refLists: [String] = [
            "01GTDW96B5AKKXQ1FB22XCXYB7",
        ]

        var vis = Post.Visibility.public
        func nextVis() -> Post.Visibility {
            switch vis {
            case .public: vis = .followers
            case .followers: vis = .home
            case .home: vis = .public
            default: vis = .public
            }
            return vis
        }

        var ans = [TestPost]()
        for text in texts {
            for attachment in maybeNilGenerator(attachments) {
                for poll in maybeNilGenerator(polls) {
                    for renote in maybeNilGenerator(refLists) {
                        for reply in maybeNilGenerator(refLists) {
                            let post = Post(
                                text: text,
                                attachments: [],
                                poll: poll,
                                cw: nil,
                                localOnly: Bool.random(),
                                visibility: nextVis(),
                                visibleUserIds: []
                            )
                            if let attachment { post.attachments = [attachment] }
                            let testItem = TestPost(
                                post: post,
                                renote: renote,
                                reply: reply
                            )
                            ans.append(testItem)
                        }
                    }
                }
            }
        }
        XCTAssert(!ans.isEmpty)
        print("[+] built \(ans.count) test post")
        return ans
    }

    private func maybeNilGenerator<T>(_ input: [T]) -> [T?] {
        [nil] + input
    }

    func checkApi_NotesStatus() {
        let nid = "01GTDT516GCNWB7XBPMXHXR9JW"
        let emoji = "🤣"

        dispatchAndWait {
            let ans = source.network.requestForNote(with: nid)
            unwrapOrFail(ans) { note in
                XCTAssert(note.id == nid)
                unwrapOrFail(note.text) { XCTAssert(!$0.isEmpty) }
                XCTAssert(note.myReaction == nil)
            }

            let stats = source.network.requestForNoteState(with: nid)
            unwrapOrFail(stats) { dic in
                XCTAssert(!dic.isEmpty)
                XCTAssert(dic["isFavorited"] as? Bool == false)
            }
        }

        // reaction create
        dispatchAndWait {
            _ = source.network.requestForReactionCreate(with: nid, reaction: emoji)
            let ans = source.network.requestForNote(with: nid)
            unwrapOrFail(ans) { note in
                XCTAssert(note.id == nid)
                XCTAssert(note.myReaction == emoji)
            }
        }

        // reaction delete
        dispatchAndWait {
            _ = source.network.requestForReactionDelete(with: nid)
            let ans = source.network.requestForNote(with: nid)
            unwrapOrFail(ans) { note in
                XCTAssert(note.id == nid)
                XCTAssert(note.myReaction == nil)
            }
        }

        // favorite create
        dispatchAndWait {
            source.network.requestForNoteFavoriteCreate(with: nid)
            let stats = source.network.requestForNoteState(with: nid)
            unwrapOrFail(stats) { dic in
                XCTAssert(!dic.isEmpty)
                XCTAssert(dic["isFavorited"] as? Bool == true)
            }
        }

        // favorite delete
        dispatchAndWait {
            source.network.requestForNoteFavoriteDelete(with: nid)
            let stats = source.network.requestForNoteState(with: nid)
            unwrapOrFail(stats) { dic in
                XCTAssert(!dic.isEmpty)
                XCTAssert(dic["isFavorited"] as? Bool == false)
            }
        }
    }

    func checkApi_Timeline() {
        var anchorA: NMNote?
        var anchorB: NMNote?
        var anchorC: NMNote?
        dispatchAndWait {
            anchorA = source.network.requestForNoteCreate(
                with: NMPost.converting(Post(text: "anchorA"))!,
                renoteId: nil,
                replyId: nil
            )?.result
            sleep(3)
            anchorB = source.network.requestForNoteCreate(
                with: NMPost.converting(Post(text: "anchorB"))!,
                renoteId: nil,
                replyId: nil
            )?.result
            sleep(3)
            anchorC = source.network.requestForNoteCreate(
                with: NMPost.converting(Post(text: "anchorC"))!,
                renoteId: nil,
                replyId: nil
            )?.result
        }
        guard let anchorA, let anchorB, let anchorC else {
            XCTFail("failed to create anchor notes")
            return
        }
        print("[+] anchor created A \(anchorA.id) B \(anchorB.id) C \(anchorC.id)")
        dispatchAndWait {
            for timelineEndpoint in TimelineSource.Endpoint.allCases {
                let fetch = source.network.requestForUserTimeline(
                    using: timelineEndpoint.rawValue,
                    limit: 20,
                    sinceDate: nil,
                    untilDate: nil,
                    sinceId: nil,
                    untilId: nil
                )
                unwrapOrFail(fetch)
                unwrapOrFail(fetch.result) { notes in
                    XCTAssert(!notes.isEmpty)
                }
            }
        }
        let uid = anchorC.id
        // find = anchorB.id
        let sid = anchorA.id
        dispatchAndWait {
            for timelineEndpoint in TimelineSource.Endpoint.allCases {
                let fetch = source.network.requestForUserTimeline(
                    using: timelineEndpoint.rawValue,
                    limit: 20,
                    sinceDate: nil,
                    untilDate: nil,
                    sinceId: sid,
                    untilId: uid
                )
                unwrapOrFail(fetch)
                unwrapOrFail(fetch.result) { notes in
                    XCTAssert(!notes.isEmpty)
                    XCTAssert(notes.count == 1)
                }
            }
        }
        var sdate: Date?
        var udate: Date?
        dispatchAndWait {
            unwrapOrFail(source.network.requestForNote(with: sid)) {
                sdate = Note.converting($0)?.date
            }
            unwrapOrFail(source.network.requestForNote(with: uid)) {
                udate = Note.converting($0)?.date
            }
        }
        guard let udate, let sdate else {
            XCTFail("unable to locate date for clipper")
            return
        }
        dispatchAndWait {
            for timelineEndpoint in TimelineSource.Endpoint.allCases {
                let fetch = source.network.requestForUserTimeline(
                    using: timelineEndpoint.rawValue,
                    limit: 20,
                    sinceDate: sdate.addingTimeInterval(1),
                    untilDate: udate.addingTimeInterval(-1),
                    sinceId: nil,
                    untilId: nil
                )
                unwrapOrFail(fetch)
                unwrapOrFail(fetch.result) { notes in
                    XCTAssert(!notes.isEmpty)
                    XCTAssert(notes.count == 1)
                }
            }
            for timelineEndpoint in TimelineSource.Endpoint.allCases {
                let fetch = source.network.requestForUserTimeline(
                    using: timelineEndpoint.rawValue,
                    limit: 20,
                    sinceDate: sdate.addingTimeInterval(1),
                    untilDate: udate.addingTimeInterval(-1),
                    sinceId: sid,
                    untilId: uid
                )
                unwrapOrFail(fetch)
                unwrapOrFail(fetch.result) { notes in
                    XCTAssert(!notes.isEmpty)
                    XCTAssert(notes.count == 1)
                }
            }
        }
    }

    func checkApi_NotesReplies() {
        dispatchAndWait {
            let nid = "01GTDT6PRZ8X66W18PWZGP66JP"
            let post = Post(text: "Hello")
            let replyNote = source.network.requestForNoteCreate(
                with: NMPost.converting(post)!,
                renoteId: nil,
                replyId: nid
            )?.result
            guard let replyNote else {
                XCTFail("failed to create note")
                return
            }
            defer {
                _ = source.network.requestForReactionDelete(with: replyNote.id)
            }
            unwrapOrFail(replyNote.replyId) { XCTAssert($0 == nid) }
            let replies = source.network.requestForReplies(toNoteWithId: nid)
            unwrapOrFail(replies)
            unwrapOrFail(replies.result) {
                unwrapOrFail($0) { XCTAssert($0.map(\.id).contains(replyNote.id)) }
            }
        }
    }

    func checkApi_NotesSearch() {
        dispatchAndWait {
            let hashtag = "#test\(Int.random(in: 10_000_000 ... 20_000_000))"
            let searchKey = "绝对清澈，绝对透明，绝对空灵，就是深邃。"
            let post = Post(text: hashtag + "\n" + searchKey)
            let ans = source.network.requestForNoteCreate(
                with: NMPost.converting(post)!,
                renoteId: nil,
                replyId: nil
            )?.result
            guard let ans else {
                XCTFail("failed to create note")
                return
            }
            defer {
                _ = source.network.requestForReactionDelete(with: ans.id)
            }
            sleep(5) // wait for index
            let search = source.network.requestForNoteSearch(query: searchKey)
            unwrapOrFail(search)
            unwrapOrFail(search.result) {
                unwrapOrFail($0) { XCTAssert($0.map(\.id).contains(ans.id)) }
            }
            let hashtagSearch = source.network.requestForHashtagsNotes(tag: hashtag)
            unwrapOrFail(hashtagSearch)
            unwrapOrFail(hashtagSearch?.result) {
                unwrapOrFail($0) { XCTAssert($0.map(\.id).contains(ans.id)) }
            }
        }
    }

    func checkApi_NotesPollVote() {
        dispatchAndWait {
            let postA = NMPost.converting(Post(poll: Post.Poll(expiresAt: nil, choices: [
                "miao", "miaomiaomiao", "miaomiaomiaomiaomiaomiao",
            ], multiple: true)))!
            let postB = NMPost.converting(Post(poll: Post.Poll(expiresAt: nil, choices: [
                "miao", "miaomiaomiao", "miaomiaomiaomiaomiaomiao",
            ], multiple: false)))!
            let postC = NMPost.converting(Post(poll: Post.Poll(expiresAt: Date().addingTimeInterval(3), choices: [
                "miao", "miaomiaomiao", "miaomiaomiaomiaomiaomiao",
            ], multiple: false)))!
            guard let noteA = source.network.requestForNoteCreate(with: postA, renoteId: nil, replyId: nil)?.result,
                  let noteB = source.network.requestForNoteCreate(with: postB, renoteId: nil, replyId: nil)?.result,
                  let noteC = source.network.requestForNoteCreate(with: postC, renoteId: nil, replyId: nil)?.result
            else {
                XCTFail("failed to create test notes")
                return
            }

            _ = source.network.requestForPollVote(with: noteA.id, choice: 0)
            _ = source.network.requestForPollVote(with: noteA.id, choice: 1)
            _ = source.network.requestForPollVote(with: noteB.id, choice: 0)
            _ = source.network.requestForPollVote(with: noteB.id, choice: 1)
            sleep(6)
            _ = source.network.requestForPollVote(with: noteC.id, choice: 0)

            guard let ansA = source.network.requestForNote(with: noteA.id),
                  let ansB = source.network.requestForNote(with: noteB.id),
                  let ansC = source.network.requestForNote(with: noteC.id)
            else {
                XCTFail("failed to update notes")
                return
            }

            unwrapOrFail(ansA.poll) {
                XCTAssert($0.choices[0].isVoted == true)
                XCTAssert($0.choices[1].isVoted == true)
                XCTAssert($0.choices[2].isVoted == false)
            }
            unwrapOrFail(ansB.poll) {
                XCTAssert($0.choices[0].isVoted == true)
                XCTAssert($0.choices[1].isVoted == false)
                XCTAssert($0.choices[2].isVoted == false)
            }
            unwrapOrFail(ansC.poll) {
                XCTAssert($0.choices[0].isVoted == false)
                XCTAssert($0.choices[1].isVoted == false)
                XCTAssert($0.choices[2].isVoted == false)
            }
        }
    }
}
