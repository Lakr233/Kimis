//
//  NoteTreeResolver+IRC.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/4.
//

import Foundation
import Storage

extension NoteTreeResolver {
    // 裁剪对一条嘟文的回复链
    class IRC: Equatable, Hashable, Identifiable {
        let father: NoteID

        // 由 StageA 传下来 表示跟节点往前还有数据
        let incompleteFather: NoteID?

        // 裁剪完成的 reply section
        var replySections: [ReplySection] = []

        struct ReplySection {
            var list: [NoteID]
            var trimmed: Bool
        }

        init(father: NoteID, incompleteFather: NoteID?) {
            self.father = father
            self.incompleteFather = incompleteFather
        }

        func feedReplies(list: [NoteID]) {
            guard !list.isEmpty else { return }

            var list = list
//            var trimmed = false

            // 如果头节点和 father 一致 则删除头节点
            if list.first == father { list.removeFirst() }

//          时间线构造改算法了 现在不裁剪了
//            // 裁剪到最后 k 个
//            while list.count > NoteTreeResolver.resolverReplyLimit {
//                list.removeFirst()
//                trimmed = true
//            }

            // 创建回复点
            replySections.append(.init(list: list, trimmed: false))
//            replySections.append(.init(list: list, trimmed: trimmed))

            // 额外说明
            // 丢弃的数据可能会包含设置的 timeline requirements
            // 但是这部分数据直接丢弃比较好 用户可以在嘟文详情页面查看完整的回复链
        }

        static func == (lhs: IRC, rhs: IRC) -> Bool {
            #if DEBUG
                if lhs.father == rhs.father {
                    assert(lhs.incompleteFather == rhs.incompleteFather)
                }
            #endif
            return lhs.father == rhs.father
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(father)
        }
    }
}

extension NoteNode.Replies {
    convenience init(with builder: NoteTreeResolver.IRC.ReplySection) {
        self.init(list: builder.list, trimmed: builder.trimmed)
    }
}

extension NoteNode {
    convenience init(with builder: NoteTreeResolver.IRC, storage: KVStorage<Note>) {
        let replies: [Replies] = builder.replySections
            .filter { !$0.list.isEmpty }
            .map { Replies(with: $0) }
            .sorted { a, b in
                guard let ad = a.list.last,
                      let bd = b.list.last,
                      let an = storage.retain(ad),
                      let bn = storage.retain(bd)
                else {
                    assertionFailure()
                    return false
                }
                return an.date > bn.date
            }
        self.init(main: builder.father, incompleteHeader: builder.incompleteFather, replies: replies)
    }
}
