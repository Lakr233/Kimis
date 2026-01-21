//
//  Request+Notes.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation

public extension Network {
    struct NoteFetchResult<T: Any> {
        public let result: T
        public let extracted: [NMNote]
    }

    /// try to decode NMNote from a serialized object, where [object] is in the array
    /// - Parameter object: json representation of object
    /// - Returns: the note if possible
    func tryDecodeNote(from object: Any) -> NMNote? {
        if let json = try? JSONSerialization
            .data(withJSONObject: object, options: .fragmentsAllowed),
            let ret = try? decoder.decode(NMNote.self, from: json)
        {
            return ret
        }
        return nil
    }

    /*
     we drop nested items in structure definition, ignored completely, because
     - we have replyId and renoteId for interface to locate the resources
     - Swift doesn't do friendly for that

     so this is an optimization for extracting those nested notes
     because we want to write them to cache database
     thus we don't need to download them repeatedly
     */

    func searchNestedObjectsForNotes(inside object: Any, depth: Int = 0, context: inout [NMNote], contextKeys: inout Set<String>) {
        guard depth < 5 else { return } // fuck
        // it sucks
        guard let object = object as? [String: Any] else {
            return
        }
        // then search for nested reply renote
        if let object = object["reply"] as? [String: Any],
           let note = tryDecodeNote(from: object)
        {
            if !contextKeys.contains(note.id) {
                contextKeys.insert(note.id)
                context.append(note)
            }
            searchNestedObjectsForNotes(inside: object, depth: depth + 1, context: &context, contextKeys: &contextKeys)
        }
        if let object = object["renote"] as? [String: Any],
           let note = tryDecodeNote(from: object)
        {
            if !contextKeys.contains(note.id) {
                contextKeys.insert(note.id)
                context.append(note)
            }
            searchNestedObjectsForNotes(inside: object, depth: depth + 1, context: &context, contextKeys: &contextKeys)
        }
    }

    func decodeResponseAndLookForNotes(jsonData: Data, noteArrayKeyPath: [String] = []) -> NoteFetchResult<[NMNote]> {
        guard let notesBuild = try? JSONSerialization
            .jsonObject(with: jsonData, options: .allowFragments)
            as? [Any]
        else {
            return .init(result: [], extracted: [])
        }
        var userNotes: [NMNote] = []
        var cachedNotesKeys: Set<String> = []
        var cachedNotes: [NMNote] = []

        for object in notesBuild {
            var search: Any = object
            var noteArrayKeyPath = noteArrayKeyPath
            while !noteArrayKeyPath.isEmpty {
                guard let s1 = search as? [String: Any] else { break }
                guard let s2 = s1[noteArrayKeyPath.removeFirst()] else { break }
                search = s2
            }
            guard let note = tryDecodeNote(from: search) else { continue }
            userNotes.append(note)
            searchNestedObjectsForNotes(inside: object, context: &cachedNotes, contextKeys: &cachedNotesKeys)
        }
        return .init(result: userNotes, extracted: cachedNotes)
    }
}

public extension Network {
    func requestForNote(with noteId: String) -> NMNote? {
        var request = prepareRequest(for: .notes_show)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        return decodeRequest(with: responseData)
    }

    func requestForNoteDelete(with noteId: String) {
        var request = prepareRequest(for: .notes_delete)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        makeRequest(with: request) { _ in }
    }

    func requestForNoteState(with noteId: String) -> [String: Any] {
        var request = prepareRequest(for: .notes_state)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else { return [:] }
        return (try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]) ?? [:]
    }

    func requestForReactionCreate(with noteId: String, reaction: String) -> NMNote? {
        var request = prepareRequest(for: .notes_reactions_create)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        injectBodyForPost(for: &request, with: ["reaction": reaction])
        makeRequest(with: request) { _ in }
        return requestForNote(with: noteId)
    }

    func requestForReactionDelete(with noteId: String) -> NMNote? {
        var request = prepareRequest(for: .notes_reactions_delete)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        makeRequest(with: request) { _ in }
        return requestForNote(with: noteId)
    }

    func requestForReactionUserList(with noteId: String, reaction: String, limit: Int) -> [NMUserLite]? {
        var request = prepareRequest(for: .notes_reactions)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        injectBodyForPost(for: &request, with: ["type": reaction])
        injectBodyForPost(for: &request, with: ["limit": limit])
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else { return nil }
        guard let firstDecode = (
            try? JSONSerialization.jsonObject(with: responseData),
        ) as? [[String: Any]] else { return nil }
        let list = firstDecode.compactMap { $0["user"] }
        return list.compactMap { element in // get key inside user
            decodeRequest(with: try? JSONSerialization.data(withJSONObject: element))
        }
    }

    /// get replies for this note
    /// - Parameter noteId: id
    /// - Returns: replies and extracted notes for cache
    func requestForReplies(
        toNoteWithId noteId: String,
    ) -> NoteFetchResult<[NMNote]> {
        var request = prepareRequest(for: .notes_replies)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData,
              let repliesBuilder = try? JSONSerialization
              .jsonObject(with: responseData, options: .allowFragments)
              as? [Any]
        else {
            print("decode timeline data failed for request \(request)")
            return .init(result: [], extracted: [])
        }

        var replies: [NMNote] = []
        var cachedNotesKeys: Set<String> = []
        var cachedNotes: [NMNote] = []

        for object in repliesBuilder {
            guard let note = tryDecodeNote(from: object) else { continue }
            replies.append(note)
            searchNestedObjectsForNotes(inside: object, context: &cachedNotes, contextKeys: &cachedNotesKeys)
        }

        return .init(result: replies, extracted: cachedNotes)
    }

    func requestForPollVote(with noteId: String, choice: Int) -> NMNote? {
        var request = prepareRequest(for: .notes_polls_vote)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        injectBodyForPost(for: &request, with: ["choice": choice])
        makeRequest(with: request) { _ in }
        return requestForNote(with: noteId)
    }

    func requestForNoteCreate(with post: NMPost, renoteId: String?, replyId: String?) -> NoteFetchResult<NMNote?>? {
        var request = prepareRequest(for: .notes_create)
        guard let postData = try? encoder.encode(post),
              let postObject = try? JSONSerialization.jsonObject(with: postData) as? [String: Any]
        else {
            assertionFailure()
            return nil
        }
        injectBodyForPost(for: &request, with: postObject)
        if let renoteId {
            injectBodyForPost(for: &request, with: ["renoteId": renoteId])
        }
        if let replyId {
            injectBodyForPost(for: &request, with: ["replyId": replyId])
        }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let data = responseData,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let searchItem = object["createdNote"],
              let searchData = try? JSONSerialization.data(withJSONObject: [searchItem])
        else {
            return nil
        }
        let result = decodeResponseAndLookForNotes(jsonData: searchData)
        guard result.result.count == 1 else {
            if result.result.count > 1 { assertionFailure() }
            return nil
        }
        return .init(result: result.result[0], extracted: result.extracted)
    }
}

public extension Network {
    func requestForNoteFavoriteCreate(with noteId: String) {
        var request = prepareRequest(for: .notes_favorites_create)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        makeRequest(with: request) { _ in }
    }

    func requestForNoteFavoriteDelete(with noteId: String) {
        var request = prepareRequest(for: .notes_favorites_delete)
        injectBodyForPost(for: &request, with: ["noteId": noteId])
        makeRequest(with: request) { _ in }
    }
}

public extension Network {
    func requestForNoteSearch(query: String, limit: Int = 20, untilId: String? = nil) -> NoteFetchResult<[NMNote]> {
        var request: URLRequest = prepareRequest(for: .notes_search)
        injectBodyForPost(for: &request, with: [
            "query": query,
            "limit": limit,
        ])
        if let untilId { injectBodyForPost(for: &request, with: ["untilId": untilId]) }
        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }
        guard let responseData else {
            return .init(result: [], extracted: [])
        }
        let result = decodeResponseAndLookForNotes(jsonData: responseData)
        return result
    }
}
