//
//  NoteTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/17.
//

import Combine
import Source
import UIKit

class NoteTableView: TableView {
    @Published var displayingCells: Set<NoteID> = []
    @Published var scrollLocation: CGPoint = .zero

    @Published var layoutWidth: CGFloat = 0
    let updatedSource = CurrentValueSubject<[NoteCell.Context], Never>([])
    let refreshCaller = CurrentValueSubject<Bool, Never>(true)

    let renderQueue = DispatchQueue(label: "wiki.qaq.timeline.render")
    var renderTicket = UUID()

    var context: [NoteCell.Context] = []
    let progressIndicator = ProgressFooterView()
    @Published var footerProgressWorkingJobs = 0 {
        didSet { if footerProgressWorkingJobs < 0 { footerProgressWorkingJobs = 0 } }
    }

    let dataUpdateLock = NSLock()
    var onSelect: ((_ note: NoteID) -> Void)?

    struct Option {
        let useBuiltinRender: Bool

        init(useBuiltinRender: Bool = true) {
            self.useBuiltinRender = useBuiltinRender
        }
    }

    let option: Option

    init(option: Option = .init()) {
        self.option = option

        super.init()

        delegate = self
        dataSource = self

        NoteCell.registeringCells(for: self)

        register(FooterCountView.self, forHeaderFooterViewReuseIdentifier: FooterCountView.identifier)

        prepareFooter()
        preparePublisher()
    }

    override func layoutSubviews() {
        if layoutWidth != bounds.width {
            renderVisibleCellAndUpdate()
            layoutWidth = bounds.width
        } else {
            reconfigureVisibleCells()
        }
        super.layoutSubviews()
    }

    func didSelect(_ note: NoteID) {
        if let onSelect {
            onSelect(note)
        } else {
            ControllerRouting.pushing(tag: .note, referencer: self, associatedData: note)
        }
    }

    func renderVisibleCellAndUpdate() {
        let visibleIndexPaths = indexPathsForVisibleRows ?? []
        for indexPath in visibleIndexPaths {
            let context = retainContext(atIndexPath: indexPath)
            context?.renderLayout(usingWidth: bounds.width)
        }
        updateAndReconfigureVisibleCells()
    }

    func updateAndReconfigureVisibleCells() {
        let locked = dataUpdateLock.try()
        defer { if locked {
            dataUpdateLock.unlock()
        } }
        beginUpdates()
        reconfigureVisibleCells()
        endUpdates()
    }

    func reconfigureVisibleCells() {
        let visibleIndexPaths = indexPathsForVisibleRows ?? []
        for indexPath in visibleIndexPaths {
            guard let cell = cellForRow(at: indexPath) as? NoteCell else {
                continue
            }
            guard let context = retainContext(atIndexPath: indexPath) else {
                continue
            }
            cell.load(data: context)
        }
    }
}
