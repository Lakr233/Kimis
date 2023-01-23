//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Foundation

public extension TimelineSource {
    /// 此方法将会请求网络 下载时间线 并从时间线解压提取 feed
    /// 同时会从远端拉取需要的 feed 包含回复和转发 以及上下文
    /// 在和本地的时间线缓存合并以后会用于展示
    /// 最后由 buildTimeline 组装成时间线的 UI 界面
    /// 一次只能有一个刷新请求在跑
    func requestUpdate(direction: FetchDirection, reset: Bool = false) {
        guard !Thread.isMainThread else {
            DispatchQueue.global().async { self.requestUpdate(direction: direction) }
            return
        }

        fetcherSenderLock.lock()
        fetcherQueue.cancelAllOperations()
        fetcherQueue.waitUntilAllOperationsAreFinished()
        if reset { beginTransaction { order in
            self.requestIR = []
            self.dataSource = .init(orderEqualAndBefore: order, nodes: [])
            self.patches.append(.init(kind: .replace, order: order, nodes: []))
        } }
        guard let base = collectExistsDataset() else { return }
        let fetcher = Fetcher(base: base, timelineSource: self, direction: direction)
        fetcherQueue.addOperation(fetcher)
        fetcherSenderLock.unlock()
    }

    internal func collectExistsDataset() -> ExistedDataSet? {
        guard let ctx else { return nil }
        let ans = ExistedDataSet(
            ctx: ctx,
            endpoint: endpoint.rawValue,
            IR: requestIR,
            notes: Set<NoteID>(dataSource.nodes.flatMap { $0.representedNotes() }),
            anchor: .init(dataset: requestIR, ctx: ctx)
        )
        return ans
    }
}

extension TimelineSource {
    class Fetcher: Operation {
        let base: ExistedDataSet
        weak var timelineSource: TimelineSource?
        let direction: FetchDirection

        init(base: ExistedDataSet, timelineSource: TimelineSource, direction: FetchDirection) {
            self.base = base
            self.timelineSource = timelineSource
            self.direction = direction

            super.init()
        }

        override func main() {
            usleep(20000)
            if isCancelled { return }
            timelineSource?.updating = true
            workItemRequestUpdate()
            timelineSource?.updating = false
        }

        deinit { print("[*] TimelineSource.Fetcher calling deinit") }

        private func workItemRequestUpdate() {
            let downloadResult = base.ctx.req.requestTimeline(
                endpoint: base.endpoint,
                untilId: direction == .older ? base.anchor?.oldest.id : NoteID?.none
            )
            guard !downloadResult.isEmpty, !isCancelled else { return }

            let downloadAnchor = Anchor(dataset: downloadResult, ctx: base.ctx)
            let inheritExists: Bool
            switch direction {
            case .older:
                inheritExists = true
            case .newer:
                inheritExists = downloadAnchor?.hasIntersection(to: base.anchor, withinCtx: base.ctx)
                    ?? false
            }

            // 拉取额外的数据通常要消耗一段时间走网络请求
            requestExtraNoteInfo(with: downloadResult)
            guard !isCancelled else { return }

            // 打开全部的 node 来做去重

            let constructorIR = downloadResult.filter { id in
                // remove duplicates
                if base.notes.contains(id) { return false }
                guard let note = base.ctx.notes.retain(id) else { return false }
                // do not put strange item back!
                guard let anchor = base.anchor else { return true }
                switch direction {
                case .newer: return note.date > anchor.newest.date
                case .older: return note.date < anchor.oldest.date
                }
            }

            guard !constructorIR.isEmpty else { return }
            guard !isCancelled else { return }

            let resolver = NoteTreeResolver(requirements: constructorIR, storage: base.ctx.notes)
            let firstReolve = resolver.resolve()

            guard !isCancelled else { return } // last check

            guard let timelineSource else { return }

            let nodeResult = timelineSource.filteringMuted(nodes: firstReolve)
            guard !nodeResult.isEmpty else { return }

            var newIR = inheritExists ? base.IR : []
            downloadResult.forEach { newIR.insert($0) }

            timelineSource.beginTransaction { order in
                print("IR checking \(timelineSource.requestIR.count) -> \(newIR.count)")

                timelineSource.requestIR = newIR
                guard inheritExists else {
                    timelineSource.patches.append(.init(kind: .replace, order: order, nodes: nodeResult))
                    return
                }
                switch self.direction {
                case .newer: timelineSource.patches.append(.init(kind: .insert, order: order, nodes: nodeResult))
                case .older: timelineSource.patches.append(.init(kind: .append, order: order, nodes: nodeResult))
                }
            }
        }

        internal func requestExtraNoteInfo(with items: [NoteID]) {
            let sem = DispatchSemaphore(value: 5)
            let group = DispatchGroup()
            for nid in items {
                sem.wait()
                group.enter()
                DispatchQueue.global().async {
                    defer {
                        sem.signal()
                        group.leave()
                    }
                    guard !self.isCancelled else { return }
                    self.requestExtraNoteInfoForReply(withNoteId: nid)
                }
            }
            group.wait()
        }

        private func requestExtraNoteInfoForReply(withNoteId noteId: NoteID, searchDepth: Int = 0) {
            /*

             拉取额外数据 流程说明 对应处理三种嘟文 note, renote, reply

             > note
             此类数据会被标记为 “需要展示”
             此类数据不需要拉取更多信息 直接处理

             > renote
             此类数据会被标记为 “需要展示”
             同时需要拉取更多的信息

             > reply
             此类数据并不会被标记为需要展示，需要额外解析一些数据
             会开始从当前节点开始往上找头 并将整颗树设置为需要展示
             如果不能在本地找到嘟文的头 或者网络请求总层数超过三层 则添加一个加载更多的头

             不论哪一种拉取 对本地展示的数据均不更新 稍后交由视图层触发更新
             eg: 页面停留超过 3 秒 发起更新请求

             */

            assert(!Thread.isMainThread)

            // 先拿到数据
            var note: Note?
            if let retainNote = base.ctx.notes.retain(noteId) {
                note = retainNote
            } else { // request to get
                if let rawNote = base.ctx.network.requestForNote(with: noteId) {
                    print("[*] requesting extra note remote info with id \(noteId)")
                    base.ctx.spider.spidering(rawNote)
                }
                if let retainNote = base.ctx.notes.retain(noteId) {
                    note = retainNote
                }
            }
            guard let note else {
                print("[E] unable to retain a note with id \(noteId)")
                return
            }

            // 仅处理回复的消息 并且没有超出拉取限制
            if let inReplyTo = note.replyId, searchDepth < 3 {
                // 递归下载新数据
                requestExtraNoteInfoForReply(withNoteId: inReplyTo, searchDepth: searchDepth + 1)
            }
            if let inRenoteTo = note.renoteId, searchDepth < 3 {
                // 递归下载新数据 renote 只下载一条
                requestExtraNoteInfoForReply(withNoteId: inRenoteTo, searchDepth: searchDepth + 100_000)
            }
        }
    }
}

extension TimelineSource {
    struct ExistedDataSet {
        let ctx: Source
        let endpoint: String
        let IR: Set<NoteID>
        let notes: Set<NoteID>
        let anchor: Anchor?

        init(ctx: Source, endpoint: String, IR: Set<NoteID>, notes: Set<NoteID>, anchor: Anchor?) {
            self.ctx = ctx
            self.endpoint = endpoint
            self.IR = IR
            self.notes = notes
            self.anchor = anchor
        }
    }
}

extension TimelineSource {
    struct Anchor {
        struct AnchorElement {
            let id: NoteID
            let date: Date
        }

        let oldest: AnchorElement
        let newest: AnchorElement

        init(oldest: AnchorElement, newest: AnchorElement) {
            self.oldest = oldest
            self.newest = newest

            assert(oldest.date <= newest.date)
        }

        init?(dataset: [NoteID], ctx: Source) {
            self.init(dataset: Set<NoteID>(dataset), ctx: ctx)
        }

        init?(dataset: Set<NoteID>, ctx: Source) {
            var dataset = dataset
            var head: Note?
            while head == nil, !dataset.isEmpty {
                head = ctx.notes.retain(dataset.removeFirst())
            }
            guard let head else { return nil }

            var oldestFeedID: NoteID = head.noteId
            var oldestFeedDate: Date = head.date
            var newestFeedID: NoteID = head.noteId
            var newestFeedDate: Date = head.date

            for noteId in dataset {
                guard let note = ctx.notes.retain(noteId) else { continue }
                if note.date > newestFeedDate {
                    newestFeedDate = note.date
                    newestFeedID = note.noteId
                }
                if note.date < oldestFeedDate {
                    oldestFeedDate = note.date
                    oldestFeedID = note.noteId
                }
            }

            self.init(
                oldest: .init(id: oldestFeedID, date: oldestFeedDate),
                newest: .init(id: newestFeedID, date: newestFeedDate)
            )
        }

        func hasIntersection(to IR: Set<NoteID>?, withinCtx ctx: Source) -> Bool {
            guard let IR else { return false }
            guard let compare = Anchor(dataset: IR, ctx: ctx) else { return false }
            return hasIntersection(to: compare, withinCtx: ctx)
        }

        func hasIntersection(to anotherAnchor: Self?, withinCtx _: Source) -> Bool {
            guard let compare = anotherAnchor else { return false }
            let rangeA = oldest.date ... newest.date
            let rangeB = compare.oldest.date ... compare.newest.date
            return rangeA.overlaps(rangeB)
        }
    }
}
