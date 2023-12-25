//
//  NoteTreeResolver+IRB.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/4.
//

import Foundation

extension NoteTreeResolver {
    class IRBReplyNode: Equatable, Hashable, Identifiable {
        let id: UUID = .init()
        var noteId: NoteID
        var subReplies: [IRBReplyNode] = []
        weak var father: IRBReplyNode?

        init(noteId: NoteID, father: IRBReplyNode?) {
            self.noteId = noteId
            self.father = father
        }

        static func == (lhs: IRBReplyNode, rhs: IRBReplyNode) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    class IRB: Equatable, Hashable, Identifiable {
        let id: UUID = .init()

        var father: NoteID
        var replyNode = IRBReplyNode(noteId: "", father: nil)

        var incompleteFather: NoteID?

        init(father: NoteID, incompleteFather: NoteID?) {
            self.father = father
            self.incompleteFather = incompleteFather
        }

        private func deepPush(list: [NoteID], target: IRBReplyNode) {
            guard !list.isEmpty else { return }
            var newList = list
            let targetToInsert = newList.removeFirst()
            for search in target.subReplies {
                if search.noteId == targetToInsert {
                    deepPush(list: newList, target: search)
                    return
                }
            }
            let node = IRBReplyNode(noteId: targetToInsert, father: target)
            target.subReplies.append(node)
            deepPush(list: newList, target: node)
        }

        func insertReply(list: [NoteID]) {
            assert(list.first == father)
            deepPush(list: [NoteID](list.dropFirst()), target: replyNode)
        }

        private func dumpReplyList(node: IRBReplyNode, depth: Int = 0) {
            let spacer = [String](repeating: " ", count: depth).joined()
            print("\(spacer) -> \(node.noteId)")
            for sub in node.subReplies {
                dumpReplyList(node: sub, depth: depth + 1)
            }
        }

        private func obtainList(from: IRBReplyNode?) -> [NoteID] {
            guard let from,
                  !from.noteId.isEmpty
            else {
                return []
            }
            return obtainList(from: from.father) + [from.noteId]
        }

        #if DEBUG
            private var compiled = false
        #endif

        func compile() -> IRC {
            #if DEBUG
                assert(!compiled)
                compiled = true
            #endif

            // 获取全部的最终节点
            var lastChildren = [IRBReplyNode]()
            do {
                var queue: [IRBReplyNode] = [replyNode]
                while !queue.isEmpty {
                    let first = queue.removeFirst()
                    if first.subReplies.isEmpty {
                        lastChildren.append(first)
                    } else {
                        queue.append(contentsOf: first.subReplies)
                    }
                }
            }

            // 为最终节点开始构建
            let build = IRC(father: father, incompleteFather: incompleteFather)
            for child in lastChildren {
                let fullList = [father] + obtainList(from: child)
                build.feedReplies(list: fullList)
            }

            return build
        }

        static func == (lhs: IRB, rhs: IRB) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
