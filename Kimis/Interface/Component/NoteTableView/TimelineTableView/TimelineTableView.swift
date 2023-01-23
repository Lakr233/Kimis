//
//  TimelineTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/17.
//

import Combine
import Source
import UIKit

class TimelineTableView: NoteTableView {
    let _dataBuildQueue = DispatchQueue(label: "wiki.qaq.note.table.builder")

    let updateFetchRequest = CurrentValueSubject<Bool, Never>(true)

    struct PatchReuslt: Equatable {
        let order: Int
        let context: [NoteCell.Context]
    }

    static let initialPatchOrder = Int.min

    @Published var patchResult: PatchReuslt = .init(order: initialPatchOrder, context: []) {
        didSet { assert(Thread.isMainThread) }
    }

    override var context: [NoteCell.Context] {
        get { [NoteCell.Context(kind: .separator)] + patchResult.context }
        set { assertionFailure() }
    }

    public var guider: NewItemGuider?

    init() {
        super.init(option: .init(useBuiltinRender: false))

        createPublishers()
        updateFetchRequest.send(true)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            renderVisibleCellAndUpdate()
        }
    }

    func scrollToInterest() {
        if let focus = source?.timeline.pointOfInterest {
            print("[*] setting initial focus to note \(source?.notes.retain(focus)?.text ?? "unknown")")
            withMainActor {
                self.scrollTo(note: focus, animated: true, atRelativePosition: .middle)
            }
        }
    }
}
