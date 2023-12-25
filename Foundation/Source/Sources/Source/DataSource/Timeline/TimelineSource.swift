//
//  TimelineSource.swift
//
//
//  Created by Lakr Aream on 2022/11/16.
//

import Combine
import Foundation
import Network
import Storage

private let kMaxTimelineNodeCount = 512
private let orderCounterStart = Int.min + 100

public class TimelineSource: ObservableObject {
    weak var ctx: Source?

    let fetcherQueue = OperationQueue()
    let fetcherSenderLock = NSLock()
    let transactionQueue = DispatchQueue(label: "wiki.qaq.timeline.transaction", attributes: .concurrent)

    // 保存一份缓存的 dataSource
    var dataSource: DataSource = .init(orderEqualAndBefore: Int.min, nodes: [])

    // 记录全部的 patch
    // UI 层拥有任意时刻的 dataSource 在请求 patches 之后都能构建出最新的 dataSource
    var patches: [Patch] = [] { didSet { updateAvailable.send(true) } }
    var patchOrderCounter: Int = orderCounterStart // 全局唯一自增 超过 Int.max 不如让程序崩溃

    @Published public internal(set) var updating: Bool = false
    @Published public internal(set) var sourceEndpoint: Endpoint
    public let updateAvailable = CurrentValueSubject<Bool, Never>(true)

    @PropertyStorage
    public var pointOfInterest: NoteID?

    @PropertyStorage
    var endpoint: Endpoint {
        didSet {
            sourceEndpoint = endpoint
            requestUpdate(direction: .newer, reset: true)
        }
    }

    @PropertyStorage
    var requestIR: Set<NoteID>
    // 只保存请求的 note 稍后使用时间对新请求进行过滤时使用

    public enum FetchDirection: String {
        case newer
        case older
    }

    init(context: Source) {
        ctx = context

        _requestIR = .init(key: .timelineIR, defaultValue: [], storage: context.properties)
        _endpoint = .init(key: .timelineEndpoint, defaultValue: .home, storage: context.properties)
        _pointOfInterest = .init(key: .focus, defaultValue: nil, storage: context.properties)
        _sourceEndpoint = .init(wrappedValue: _endpoint.wrappedValue)

        // 初始化数据 保留至多 128 个 IR 用于构建
        var initialIR = _requestIR.wrappedValue
            .compactMap { context.notes.retain($0) }
            .sorted { $0.date > $1.date }
        if initialIR.count > kMaxTimelineNodeCount { initialIR.removeLast(initialIR.count - kMaxTimelineNodeCount) }
        let resolver = NoteTreeResolver(requirements: initialIR.map(\.id), storage: context.notes)
        let initialBuild = filteringMuted(nodes: resolver.resolve())

        print("[*] initialized data source with \(initialBuild.count) nodes and")
        dataSource = .init(orderEqualAndBefore: orderCounterStart, nodes: initialBuild)
        patches.append(.init(kind: .replace, order: orderCounterStart, nodes: initialBuild))

        updateAvailable.send(true)
    }

    public func activate(endpoint: Endpoint) {
        print("[*] activating timeline endpoint \(endpoint)")
        self.endpoint = endpoint
    }

    func isNoteNodeMuted(_ node: NoteNode) -> Bool {
        guard let ctx else { return false }
        if ctx.isNoteMuted(noteId: node.main) { return true }
        for replySectin in node.replies {
            for reply in replySectin.list {
                if ctx.isNoteMuted(noteId: reply) { return true }
            }
        }
        return false
    }

    func filteringMuted(nodes: [NoteNode]) -> [NoteNode] {
        nodes.filter { !self.isNoteNodeMuted($0) }
    }

    func deleteNote(noteId: String) {
        print("[*] begin delete operation \(noteId)")
        beginTransaction { order in
            let newIR = self.requestIR.filter { $0 != noteId }
            self.requestIR = newIR
            let currentDataSource = self.dataSource
            self.patches.append(.init(
                kind: .replace,
                order: order,
                nodes: currentDataSource.nodes.filter { node in
                    !node.representedNotes().contains(noteId)
                }
            ))
        }
    }
}
