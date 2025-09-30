//
//  HashtagTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/28.
//

import Combine
import Source
import UIKit

class HashtagTableView: NoteTableView {
    let hashtag: String

    let updateFetchRequest = CurrentValueSubject<Bool, Never>(true)
    @Published private(set) var hashtagNoteList = [NoteID]() // keep it sorted!

    private var fetcherTicket: UUID?

    var isFetching: Bool {
        fetcherTicket != nil
    }

    init(hashtag: String) {
        self.hashtag = hashtag

        super.init()

        $hashtagNoteList
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .map { $0.map { NoteCell.Context(kind: .main, noteId: $0) } }
            .map { value in
                var build = [NoteCell.Context]()
                build.append(.init(kind: .separator))
                for item in value {
                    build.append(item)
                    build.append(.init(kind: .separator))
                }
                return build
            }
            .sink { [weak self] value in
                self?.updatedSource.send(value)
            }
            .store(in: &cancellable)

        updateFetchRequest
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                print("[*] hashtag table view $updateFetchRequest called")
                self?.beginFetch(directionNewer: value)
            }
            .store(in: &cancellable)
    }

    func beginFetch(directionNewer: Bool) {
        let ticket = UUID()
        fetcherTicket = ticket
        footerProgressWorkingJobs += 1
        DispatchQueue.global().async {
            self._beginFetch(directionNewer: directionNewer, ticket: ticket)
            self.footerProgressWorkingJobs -= 1
            self.fetcherTicket = nil
        }
    }

    private func _beginFetch(directionNewer: Bool, ticket: UUID) {
        guard let source else { return }

        var untilId: NoteID?
        if !directionNewer {
            untilId = hashtagNoteList.last
        }

        let result = source.req.requestHashtagList(tag: hashtag, until: untilId)

        guard !result.isEmpty else { return }
        guard ticket == fetcherTicket else { return }

        let insert = result.map(\.noteId)

        var compiler = hashtagNoteList
        var deduplicate = Set<NoteID>(compiler)

        var build = [NoteID]()
        for item in insert where !deduplicate.contains(item) {
            deduplicate.insert(item)
            build.append(item)
        }

        switch directionNewer {
        case true:
            compiler = build + compiler
        case false:
            compiler = compiler + build
        }
        hashtagNoteList = compiler
    }
}
