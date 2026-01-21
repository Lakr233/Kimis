//
//  NoteCell+ContextExt.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/21.
//

import Foundation

extension NoteCell.Context {
    convenience init(
        kind: NoteCell.CellKind,
        noteId: String? = nil,
        connectors: (_ connector: inout Set<ConnectorDirection>) -> Void,
    ) {
        var build: Set<ConnectorDirection> = []
        connectors(&build)
        self.init(kind: kind, noteId: noteId, connectors: build)
    }

    enum ConnectorDirection: String {
        case up
        case down
        case attach
        case pass
    }

    static func createAttachmentElements(withNote note: Note) -> [NoteAttachmentView.Elemet] {
        note.attachments.map { .init(with: $0) }
    }

    static func createReactionStripElemetns(withNote note: Note, source: Source?) -> [ReactionStrip.ReactionElement] {
        guard let source else { return [] }
        var buildReactions = [ReactionStrip.ReactionElement]()
        for (key, value) in note.reactions {
            if key.hasPrefix(":"), key.hasSuffix(":") {
                let name = String(key.dropFirst().dropLast())
                let url = source.host
                    .appendingPathComponent("emoji")
                    .appendingPathComponent(name)
                    .appendingPathExtension("webp")
                buildReactions.append(.init(
                    noteId: note.noteId,
                    text: nil,
                    url: url,
                    count: value,
                    highlight: note.userReaction == key,
                    representReaction: name,
                ))
            } else {
                buildReactions.append(.init(
                    noteId: note.noteId,
                    text: key,
                    url: nil,
                    count: value,
                    highlight: note.userReaction == key,
                ))
            }
        }
        buildReactions.sort {
            if $0.isUserReaction { return true }
            if $1.isUserReaction { return false }
            return ($0.text ?? $0.url?.absoluteString ?? "")
                < ($1.text ?? $1.url?.absoluteString ?? "")
        }
        return buildReactions
    }
}
