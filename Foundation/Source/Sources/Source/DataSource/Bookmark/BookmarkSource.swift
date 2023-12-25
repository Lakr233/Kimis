//
//  BookmarkSource.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation
import Network

private let kMaxBookmarkCount = 1024

public class BookmarkSource: ObservableObject {
    weak var ctx: Source?

    @Published public private(set) var updating: Bool = false
    @Published public private(set) var dataSource = [NoteID]() {
        didSet {
            print("[*] book mark updated \(dataSource.count) notes")
            ctx?.properties.setProperty(toKey: .bookmark, withObject: dataSource)
        }
    }

    var throttle = Date(timeIntervalSince1970: 0)

    private var ticket: UUID? {
        didSet { updating = ticket != nil }
    }

    init(context: Source) {
        ctx = context
        dataSource = context.properties.readProperty(
            fromKey: .bookmark,
            defaultValue: [NoteID]()
        )
        if dataSource.count > kMaxBookmarkCount {
            dataSource.removeLast(dataSource.count - kMaxBookmarkCount)
        }
    }

    public func fetchMoreBookmark() {
        guard ticket == nil, throttle.timeIntervalSinceNow < 0 else { return }
        let ticket = UUID()
        self.ticket = ticket
        let untilId = dataSource.last
        let orig = dataSource
        DispatchQueue.global().async {
            var throttleNext: TimeInterval = 2
            defer {
                self.ticket = nil
                self.throttle = Date() + throttleNext
            }

            let result = self.ctx?.req.requestForUserFavorites(untilId: untilId)
            if result?.isEmpty ?? false { throttleNext = 10 }

            var builder = orig
            var deduplicate = Set<NoteID>(orig)
            for item in result ?? [] where !deduplicate.contains(item) {
                builder.append(item)
                deduplicate.insert(item)
            }

            guard self.ticket == ticket else { return }
            self.dataSource = builder
        }
    }

    public func reloadBookmark(force: Bool = false) {
        guard ticket == nil, throttle.timeIntervalSinceNow < 0 || force else { return }
        let ticket = UUID()
        self.ticket = ticket
        DispatchQueue.global().async {
            defer {
                self.ticket = nil
                self.throttle = Date() + 2
            }

            let result = self.ctx?.req.requestForUserFavorites()
            guard let result, !result.isEmpty else { return }
            guard self.ticket == ticket else { return }
            self.dataSource = result
        }
    }
}
