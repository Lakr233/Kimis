//
//  TimelineSource+Patch.swift
//
//
//  Created by Lakr Aream on 2022/12/7.
//

import Foundation

public extension TimelineSource {
    // 一个 patch 代表一次变化
    enum PatchKind: String {
        // 在最前端插入内容
        case insert
        // 在最后面添加内容
        case append
        // 替换掉整条数据
        case replace
    }

    // TimelineSource 会保存全部的 Patch 记录以便 UI 端要使用内容
    // 并缓存一份最新的 dataSource
    struct Patch {
        public let kind: PatchKind
        public let order: Int
        public let nodes: [NoteNode]
    }

    // 所有的修改都是对 Patch 记录列表的修改
    // 对他修改会自动更新最新的数据

    struct DataSource {
        public let orderEqualAndBefore: Int
        public let nodes: [NoteNode]

        init(orderEqualAndBefore: Int, nodes: [NoteNode]) {
            self.orderEqualAndBefore = orderEqualAndBefore
            self.nodes = nodes
        }

        public init() {
            orderEqualAndBefore = Int.min
            nodes = []
        }
    }

    func beginTransaction(_ calling: @escaping (_ order: Int) -> Void) {
        assert(!DispatchQueue.isCurrent(transactionQueue))
        let item = DispatchWorkItem(flags: .barrier) { [self] in
            patchOrderCounter += 1
            calling(patchOrderCounter)
            // 处理全部的新 patch
            var processed = false
            for patch in patches where patch.order > dataSource.orderEqualAndBefore {
                processed = true
                print("[*] patcher is applying \(patch.kind) with \(patch.nodes.count) items")
                let orig = dataSource.nodes
                switch patch.kind {
                case .append:
                    dataSource = .init(
                        orderEqualAndBefore: patch.order,
                        nodes: orig + patch.nodes,
                    )
                case .insert:
                    dataSource = .init(
                        orderEqualAndBefore: patch.order,
                        nodes: patch.nodes + orig,
                    )
                case .replace:
                    dataSource = .init(
                        orderEqualAndBefore: patch.order,
                        nodes: patch.nodes,
                    )
                }
            }
            if processed { updateAvailable.send(true) }
        }
        transactionQueue.sync(execute: item)
    }

    func obtainDataSource() -> DataSource {
        assert(!DispatchQueue.isCurrent(transactionQueue))
        var ans: DataSource?
        transactionQueue.sync { ans = self.dataSource }
        return ans!
    }

    func obtainPatches(after: Int?) -> [Patch] {
        assert(!DispatchQueue.isCurrent(transactionQueue))
        var ans: [Patch]?
        transactionQueue.sync { ans = self.patches }
        var ret = ans!
        if let after { ret = ret.filter { $0.order > after } }
        return ret
    }
}

private extension DispatchQueue {
    static func isCurrent(_ queue: DispatchQueue) -> Bool {
        let key = DispatchSpecificKey<Void>()

        queue.setSpecific(key: key, value: ())
        defer { queue.setSpecific(key: key, value: nil) }

        return DispatchQueue.getSpecific(key: key) != nil
    }
}
