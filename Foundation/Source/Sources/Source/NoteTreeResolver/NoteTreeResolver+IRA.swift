//
//  TimelineResolver+IRA.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/4.
//

import Foundation

extension NoteTreeResolver {
    // 首次计算的内容 对回复节点进行处理 合并较小的内容
    class IRA: Equatable, Hashable, Identifiable {
        let id: UUID = .init()

        var father: NoteID
        var children: [NoteID] = []

        // 当无法解析到全部的父节点 标记不完全
        var incompleteFather: NoteID?

        init(father: NoteID, incompleteFather: NoteID?) {
            self.father = father
            self.incompleteFather = incompleteFather
        }

        func printOut() {
            print(
                """
                [IRA]
                    Father: \(father)
                    Children: \(children.joined(separator: " < "))
                """
            )
        }

        static func == (lhs: IRA, rhs: IRA) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
