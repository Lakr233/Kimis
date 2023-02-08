//
//  TimelineTableView+Builder.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/7.
//

import Combine
import UIKit

extension TimelineTableView {
    func preparePatchesIfNeededAndRenderUpdate() {
        assert(DispatchQueue.isCurrent(_dataBuildQueue))
        guard let source else { return }

        var original: PatchReuslt?
        var width: CGFloat = 0

        let item = DispatchWorkItem {
            original = self.patchResult
            width = self.width
        }
        DispatchQueue.main.asyncAndWait(execute: item)

        guard var rollingBuild = original else {
            assertionFailure()
            return
        }

        if original?.order == Self.initialPatchOrder {
            let upstream = source.timeline.obtainDataSource()
            let compile = PatchReuslt(
                order: upstream.orderEqualAndBefore,
                context: Self.translate(rawNodes: upstream.nodes)
            )
            reloadWithRenderOnly(source: compile, usingWidth: width)
        } else {
            let patches = source.timeline.obtainPatches(after: rollingBuild.order)
            print("[*] timeline table view fetched \(patches.count) patches")
            if patches.isEmpty {
                reloadWithRenderOnly(source: rollingBuild, usingWidth: width)
            } else {
                for patch in patches {
                    kApplyPatchAndRenderWithReload(
                        transactionApplyTo: &rollingBuild,
                        tableViewWidth: width,
                        patch: patch
                    )
                }
            }
        }
    }

    private func kApplyPatchAndRenderWithReload(
        transactionApplyTo patchContainer: inout PatchReuslt,
        tableViewWidth width: CGFloat,
        patch: TimelineSource.Patch
    ) {
        assert(DispatchQueue.isCurrent(_dataBuildQueue))

        var insertContentHeight = false
        var resetToTop = false
        let ctx = Self.translate(rawNodes: patch.nodes)

        switch patch.kind {
        case .replace:
            patchContainer = .init(
                order: patch.order,
                context: ctx
            )
            resetToTop = true
        case .insert:
            patchContainer = .init(
                order: patch.order,
                context: ctx + patchContainer.context
            )
            insertContentHeight = true
        case .append:
            patchContainer = .init(
                order: patch.order,
                context: patchContainer.context + ctx
            )
        }

        let renderTarget = patchContainer.context
        let render = DispatchWorkItem {
            self.render(target: renderTarget, width: width)
        }
        renderQueue.asyncAndWait(execute: render)

        let result: PatchReuslt = patchContainer
        let item = DispatchWorkItem {
            self.applyDataSource(
                result,
                insertContentHeight: insertContentHeight,
                resetToTop: resetToTop
            )
        }
        DispatchQueue.main.asyncAndWait(execute: item)
    }

    func reloadWithRenderOnly(source: PatchReuslt, usingWidth width: CGFloat) {
        print("[*] timeline table view calling reload with render only")
        let render = DispatchWorkItem {
            self.render(target: source.context, width: width)
        }
        renderQueue.asyncAndWait(execute: render)
        let item = DispatchWorkItem {
            if self.patchResult == source {
                self.updateAndReconfigureVisibleCells()
            } else {
                UIView.performWithoutAnimation {
                    self.patchResult = source
                    self.reloadData()
                }
            }
        }
        DispatchQueue.main.asyncAndWait(execute: item)
    }

    func diffableUpdate(toTarget targetResult: PatchReuslt) {
        dataUpdateLock.lock()
        defer { dataUpdateLock.unlock() }
        let recordedOffset = contentOffset
        defer { contentOffset = recordedOffset }
        UIView.performWithoutAnimation {
            beginUpdates()
            let diff = targetResult.context.difference(from: self.patchResult.context)
            for change in diff {
                switch change {
                case let .insert(offset, _, _):
                    self.insertRows(at: [IndexPath(row: offset, section: 0)], with: .none)
                case let .remove(offset, _, _):
                    self.deleteRows(at: [IndexPath(row: offset, section: 0)], with: .none)
                }
            }
            self.patchResult = targetResult
            endUpdates()
            updateAndReconfigureVisibleCells()
        }
        setNeedsLayout()
        layoutIfNeeded()
        layoutSubviews()
    }

    func applyDataSource(_ targetResult: PatchReuslt, insertContentHeight: Bool = false, resetToTop: Bool = false) {
        print("[*] timeline table view calling reload with source order at \(targetResult.order) insert \(insertContentHeight)")
        assert(Thread.isMainThread)

        let previousResult = patchResult
        let previousOffset = contentOffset
        let previousHeight = contentSize.height

        var focus = previousOffset

        if resetToTop {
            dataUpdateLock.lock()
            patchResult = targetResult
            reloadData()
            dataUpdateLock.unlock()
            focus.y = 0
            if let view = superview {
                focus.y -= view.safeAreaInsets.top
            }
            guider?.setCountMax(0)
            guider?.dismiss()
        } else {
            diffableUpdate(toTarget: targetResult)
        }

        if insertContentHeight {
            let newHeight = contentSize.height
            let diff = newHeight - previousHeight
            focus.y += diff

            let currentNotes = targetResult
                .context
                .filter { !$0.kind.isSupplymentKind }
                .count
            let previousNotes = previousResult
                .context
                .filter { !$0.kind.isSupplymentKind }
                .count
            let newNotesCount = currentNotes - previousNotes
            if newNotesCount > 0 {
                guider?.setCountMax(newNotesCount, appending: true)
                presentNewItemGuider()
            }
        }

        if focus != previousOffset {
            print("[*] timeline table view move content offset \(previousOffset.y) -> \(focus.y)")
            setContentOffset(focus, animated: false)
        }
    }

    static func translate(rawNodes: [NoteNode]) -> [NoteCell.Context] {
        var result: [[NoteCell.Context]] = []
        let builder = rawNodes.map { $0.translateToContext() }
        for idx in 0 ..< builder.count {
            let group = builder[idx]
            result.append(group)
            result.append([.init(kind: .separator)])
        }
        return result.flatMap { $0 }
    }
}
