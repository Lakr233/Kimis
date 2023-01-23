//
//  TimelineResolver.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import Foundation
import Storage

internal class NoteTreeResolver {
    internal let requirements: [NoteID]
    internal let storage: KVStorage<Note>

    internal init(requirements: [NoteID], storage: KVStorage<Note>) {
        self.requirements = requirements
        self.storage = storage
    }

    private func deepSearch(noteId: NoteID, element: inout IRA) {
        guard let note = storage.retain(noteId) else {
            // 仅处理入库的数据
            print("[i] unable to find \(noteId) locally")
            return
        }

        // 更新 father 到当前节点
        element.father = note.id
        element.incompleteFather = note.replyId

        // 将当前 note 的 id 添加到 children
        // children 表示这条解析树涵盖的 note 范围
        // 因为是向上查找 所以 children 会被在最前面添加
        element.children.insert(note.id, at: 0)

        switch NoteType.choose(note: note) {
        case .regular: return
        case .reply:
            // 对包含父节点的元素递归解析
            if let reply = note.replyId {
                deepSearch(noteId: reply, element: &element)
            } else {
                assertionFailure()
            }
            return
        }
    }

    private func buildElement(withNoteId noteId: NoteID) -> IRA? {
        // 起点为当前节点
        var element = IRA(father: noteId, incompleteFather: nil)
        // 一次一次更新查找 并同时更新 father 的值
        deepSearch(noteId: noteId, element: &element)
        // 过滤第一次查找就失败的元素
        if element.father.isEmpty || element.children.isEmpty {
            return nil
        }
        return element
    }

    private var builtBefore = false
    internal func resolve() -> [NoteNode] {
        assert(!builtBefore, "resolve should be called only once per lifecycle")
        builtBefore = true

        // 为每一个元素进行回复链表构建
        var buildAllReqs = [NoteID: [IRA]]()
        do {
            for item in requirements {
                guard let build = buildElement(withNoteId: item) else {
                    debugPrint("[E] buildElement failed \(#file) \(#line)")
                    continue
                }
                buildAllReqs[build.father, default: []].append(build)
            }
        }

        /*
         额外说明 最长链设计 在下图所示的情况下
         a
         |-> b
             |-> c
             |-> d
         |-> e

         c d e 链均会被保留 裁剪仅删除 b 这样的中间节点
         */

        var buildAllTree: [NoteID: IRB] = [:]

        // 接下来每一个 IDA 的 father 将会作为展示的要求节点
        for fatherRoot in buildAllReqs.keys {
            // 取出父节点
            guard let iras = buildAllReqs[fatherRoot] else {
                assertionFailure()
                continue
            }
            let incompleteFather = iras.first?.incompleteFather
            // incomplete 标记位应该是全部都统一的 不然不会是一个 father
            #if DEBUG
                for ira in iras { assert(ira.incompleteFather == incompleteFather) }
            #endif
            // 将所有路径混合添加
            let irb = IRB(father: fatherRoot, incompleteFather: incompleteFather)
            for ira in iras {
                irb.insertReply(list: ira.children)
            }
            buildAllTree[fatherRoot] = irb
        }

        var buildIRCs = [IRB](buildAllTree.values)
            .compactMap { $0.compile() }

        // 对节点进行排序
        buildIRCs.sort { a, b in
            // 时间线优先考虑视觉稳定性 table view 最好是能保持跟踪
            // 所以回复不当人看
            // 使用 father 的 创建时间作为时间线排序元素
            guard let lhs = storage.retain(a.father),
                  let rhs = storage.retain(b.father)
            else {
                return false
            }
            return lhs.date > rhs.date
        }

        // 转换成首页可以显示的数据模型
        let result = buildIRCs.compactMap { NoteNode(with: $0, storage: storage) }
        return result
    }
}
