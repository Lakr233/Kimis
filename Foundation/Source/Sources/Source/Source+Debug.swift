//
//  File.swift
//
//
//  Created by Lakr Aream on 2022/12/8.
//

import Foundation

#if DEBUG

    extension Source {
        func kprint(_ id: String) {
            if let note = notes.retain(id) {
                print("💬 [\(id)] \(note.text)")
            }
            if let user = users.retain(id) {
                print("🤦‍♂️ [\(id)] \(user.name)")
            }
        }

        func kprint(_ node: NoteNode) {
            print("[\(node.id)] >>>>>>>>>>")
            kprint(node.main)
            for (idx, section) in node.replies.enumerated() {
                print("> \(idx)")
                for item in section.list {
                    Swift.print("  ", separator: "", terminator: "")
                    kprint(item)
                }
            }
            print("[\(node.id)] <<<<<<<<<<")
        }

        func kprint(_ nodes: [NoteNode]) {
            for (idx, item) in nodes.enumerated() {
                print(idx)
                kprint(item)
            }
        }
    }

#endif
