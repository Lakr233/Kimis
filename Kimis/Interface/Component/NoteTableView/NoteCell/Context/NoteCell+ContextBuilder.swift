//
//  NoteCell+ContextBuilder.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/21.
//

import Foundation

private let kChainMaxLength = 2

extension NoteNode {
    func translateToContext() -> [NoteCell.Context] {
        var build = [NoteCell.Context]()

        // disable more header to make it beautiful
        //        if let header = node.incompleteHeader {
        //            build.append(.init(kind: .moreHeader, noteId: header, connectors: [.down]))
        //        }

        let mainCell = NoteCell.Context(kind: .main, noteId: main) { con in
            //            if node.incompleteHeader != nil { con.insert(.up) }
            if !self.replies.isEmpty { con.insert(.down) }
        }
        build.append(mainCell)

        if replies.isEmpty {
            // 只有一组回复
        } else if replies.count == 1 {
            var replyBuilder = replies[0].list.map {
                NoteCell.Context(kind: .reply, noteId: $0, connectors: [.up, .down])
            }
            if replyBuilder.count > kChainMaxLength {
                replyBuilder.removeFirst(replyBuilder.count - kChainMaxLength)
                replyBuilder.insert(.init(kind: .moreReply, noteId: replyBuilder.first?.noteId, connectors: [.up, .down]), at: 0)
            }
            replyBuilder.last?.connectors.remove(.down)
            build.append(contentsOf: replyBuilder)
        } else if let optimized = optimizedCommonHeader() {
            build.append(contentsOf: optimized)
        } else {
            var repliesCtx = replies.compactMap { replyItem -> NoteCell.Context? in
                guard let firstReply = replyItem.list.first else {
                    return nil
                }
                let ctx = NoteCell.Context(
                    kind: .replyPadded,
                    noteId: firstReply,
                    connectors: [.attach, .pass],
                )
                return ctx
            }
            repliesCtx.removeDuplicates()
            if repliesCtx.count == 1 {
                repliesCtx[0] = .init(
                    kind: .reply,
                    noteId: repliesCtx[0].noteId,
                    connectors: repliesCtx[0].connectors,
                )
            } else if repliesCtx.count >= 3 {
                // 有太多的回复 大概率是关注的 po 主回复了一堆人 实测两条已经很顶了 所以加一层处理
                // 关闭 operation button 和 header
                for item in repliesCtx {
                    item.disableOperationStrip = true
                    item.disablePreviewReason = true
                }
            }
            repliesCtx.sort { $0.noteId ?? "" < $1.noteId ?? "" }
            repliesCtx.last?.connectors.remove(.pass)
            build.append(contentsOf: repliesCtx)
        }

        for idx in 0 ..< build.count {
            let nextCellIsSupplyment = build[safe: idx + 1]?.kind.isSupplymentKind ?? true
            build[idx].disablePaddingAfter = !nextCellIsSupplyment
        }

        return build
    }
}

extension NoteNode {
    func optimizedCommonHeader() -> [NoteCell.Context]? {
        var commonHeader = [NoteID]()

        guard replies.count > 1 else { return nil }

        func getCommonHeader(atIdx: Int) -> NoteID? {
            guard let candidate = replies.first?.list[safe: atIdx] else {
                return nil
            }
            for reply in replies.dropFirst() {
                guard let match = reply.list[safe: atIdx] else {
                    return nil
                }
                guard match == candidate else {
                    return nil
                }
            }
            return candidate
        }

        while let header = getCommonHeader(atIdx: commonHeader.count) {
            commonHeader.append(header)
        }
        guard commonHeader.count > 0 else { return nil }

        let nextLevel = commonHeader.count

        var build = [NoteCell.Context]()
        if commonHeader.count > kChainMaxLength {
            commonHeader.removeFirst(commonHeader.count - kChainMaxLength)
            build.append(.init(kind: .moreReply, noteId: commonHeader.last, connectors: [.up, .down]))
        }
        build.append(contentsOf: commonHeader.map {
            NoteCell.Context(
                kind: .reply,
                noteId: $0,
                connectors: [.up, .down],
            )
        })

        // 往下再 build 一层 如果有
        var nextLevelSet: Set<NoteID> = []
        for reply in replies {
            if let note = reply.list[safe: nextLevel], !nextLevelSet.contains(note) {
                let context = NoteCell.Context(
                    kind: .replyPadded,
                    noteId: note,
                    connectors: [.attach, .pass],
                )
                context.disableOperationStrip = true
                context.disablePreviewReason = true
                build.append(context)
                nextLevelSet.insert(note)
            }
        }

        build.last?.connectors.remove(.pass)
        build.last?.connectors.remove(.down)
        return build
    }
}
