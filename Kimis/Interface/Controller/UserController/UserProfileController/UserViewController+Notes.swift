//
//  UserViewController+Notes.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/28.
//

import Combine
import UIKit

extension UserViewController {
    func createNotePublisher() {
        Publishers.CombineLatest($pinnedList, $notesList)
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .removeDuplicates { $0 == $1 }
            .map { value -> [NoteCell.Context] in
                let pin: [NoteID] = value.0
                let lst: [NoteID] = value.1
                var build = [NoteCell.Context]()
                if self.fetchEndpoint == .notes || self.fetchEndpoint == .notesWithReplies {
                    for item in pin {
                        build.append(.init(kind: .pinned, noteId: item))
                        build.append(.init(kind: .separator))
                    }
                }
                for item in lst {
                    let display = NoteCell.Context(kind: .main, noteId: item)
                    display.disableRenoteOptomization = true
                    build.append(display)
                    build.append(.init(kind: .separator))
                }
                return build
            }
            .sink { [weak self] value in
                self?.tableView.updatedSource.send(value)
            }
            .store(in: &cancellable)
    }
}
