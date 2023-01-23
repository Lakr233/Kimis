//
//  NoteCell+Context.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/18.
//

import Combine
import Foundation
import Source

extension NoteCell {
    class Context: Identifiable, Hashable, Equatable {
        weak var source: Source? = Account.shared.source

        var id: Int { hashValue }

        let kind: CellKind
        var cellId: String { kind.cellId }

        let noteId: String?
        var connectors: Set<ConnectorDirection>
        var disablePaddingAfter: Bool = false
        var disableRenoteOptomization: Bool = false

        var cellHeight: CGFloat = 0

        var snapshot: (any AnySnapshot)?

        init(
            kind: NoteCell.CellKind,
            noteId: String? = nil,
            connectors: Set<ConnectorDirection> = []
        ) {
//            assert(!Thread.isMainThread || kind.isSupplymentKind)
            self.kind = kind
            self.noteId = noteId
            self.connectors = connectors
            if let height = kind.designatedHeight { cellHeight = height }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(kind)
            hasher.combine(noteId)
            hasher.combine(connectors)
        }

        static func == (lhs: NoteCell.Context, rhs: NoteCell.Context) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
