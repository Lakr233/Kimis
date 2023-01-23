//
//  NoteTableView+Render.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/22.
//

import UIKit

private extension Array {
    func splitInSubArrays(into size: Int) -> [[Element]] {
        (0 ..< size).map {
            stride(from: $0, to: count, by: size).map { self[$0] }
        }
    }
}

extension NoteTableView {
    private func _render(target: [NoteCell.Context], width: CGFloat) {
        footerProgressWorkingJobs += 1
        defer { footerProgressWorkingJobs -= 1 }

        let cores = ProcessInfo.processInfo.processorCount
        if target.count < cores * 5 {
            target.forEach { $0.renderLayout(usingWidth: width) }
        } else {
            let each = Int(target.count / cores)
            let jobs = target.splitInSubArrays(into: each)

            let group = DispatchGroup()
            for item in jobs {
                group.enter()
                let thread = Thread {
                    defer { group.leave() }
                    item.forEach { $0.renderLayout(usingWidth: width) }
                }
                thread.qualityOfService = Thread.current.qualityOfService
                thread.start()
            }
            group.wait()
        }
    }

    func render(target: [NoteCell.Context], width: CGFloat, ticket: UUID? = nil) {
        let renderBegin = Date()
        _render(target: target, width: width)
        print(
            """
            [Render] initialized render request
                \(ticket?.uuidString ?? "undefined session")
                width: \(width)
                items: \(target.count)
                time: \(Int(abs(renderBegin.timeIntervalSinceNow) * 1000))ms
            """
        )
    }

    func requestRenderUpdateReload(target: [NoteCell.Context], width: CGFloat, ticket: UUID) {
        render(target: target, width: width, ticket: ticket)

        withMainActor {
            self.requestReload(toTarget: target)
            self.renderTicket = .init()
        }
    }
}
