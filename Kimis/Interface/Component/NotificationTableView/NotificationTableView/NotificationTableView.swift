//
//  NotificationTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import Source
import UIKit

class NotificationTableView: TableView {
    @Published var scrollLocation: CGPoint = .zero

    @Published var layoutWidth: CGFloat = 0
    let refreshCaller = CurrentValueSubject<Bool, Never>(true)

    let renderQueue = DispatchQueue(label: "wiki.qaq.notifications.render")
    var renderTicket = UUID()

    internal(set) var notifications: [NotificationCell.Context] = []
    let progressIndicator = ProgressFooterView()

    var onSelect: ((_ notification: RemoteNotification) -> Void)?

    override init() {
        super.init()

        delegate = self
        dataSource = self

        NotificationCell.registeringCells(for: self)
        register(FooterCountView.self, forHeaderFooterViewReuseIdentifier: FooterCountView.identifier)

        prepareFooter()
        preparePublisher()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if layoutWidth != bounds.width {
            renderVisibleCellAndUpdate()
            layoutWidth = bounds.width
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didSelect(_ notification: RemoteNotification) {
        if let onSelect {
            onSelect(notification)
        } else {
            if let noteId = notification.noteId {
                ControllerRouting.pushing(tag: .note, referencer: self, associatedData: noteId)
            } else if let userId = notification.userId {
                ControllerRouting.pushing(tag: .user, referencer: self, associatedData: userId)
            } else {
                print("[*] having no idea about handling notification \(notification.id)")
            }
        }
    }

    func renderVisibleCellAndUpdate() {
        let visibleIndexPaths = indexPathsForVisibleRows ?? []
        for indexPath in visibleIndexPaths {
            let context = retainContext(atIndexPath: indexPath)
            context?.renderLayout(usingWidth: bounds.width, source: source)
        }
        beginUpdates()
        for indexPath in visibleIndexPaths {
            guard let cell = cellForRow(at: indexPath) as? NotificationCell else {
                continue
            }
            guard let context = retainContext(atIndexPath: indexPath) else {
                continue
            }
            cell.load(context)
        }
        endUpdates()
    }
}
