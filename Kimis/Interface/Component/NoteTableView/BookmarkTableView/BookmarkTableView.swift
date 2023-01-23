//
//  BookmarkTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import Source
import UIKit

class BookmarkTableView: NoteTableView {
    init() {
        super.init()

        source?.bookmark.$dataSource
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .removeDuplicates()
            .map { value -> [NoteCell.Context] in
                var build = [NoteCell.Context]()
                build.append(.init(kind: .separator))
                for item in value {
                    build.append(.init(kind: .main, noteId: item))
                    build.append(.init(kind: .separator))
                }
                return build
            }
            .sink { [weak self] value in
                self?.updatedSource.send(value)
            }
            .store(in: &cancellable)

        source?.bookmark.$updating
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in
                self?.footerProgressWorkingJobs += val ? 1 : -1
            }
            .store(in: &cancellable)
    }
}
