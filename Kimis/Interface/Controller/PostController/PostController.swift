//
//  PostController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import Combine
import Source
import UIKit

extension Notification.Name {
    static let postSent = Notification.Name("wiki.qaq.post.sent")
}

class PostController: UINavigationController, RouterDatable {
    struct PostContext: Codable {
        let renote: NoteID?
        let reply: NoteID?
    }

    var associatedData: Any? {
        didSet {
            print("[*] PostController setting data reply \(postContext?.reply ?? "nil") renote \(postContext?.renote ?? "nil")")
            poster.replyId = postContext?.reply
            poster.renoteId = postContext?.renote
        }
    }

    var postContext: PostContext? {
        associatedData as? PostContext
    }

    private let poster = PostEditorController()

    init() {
        super.init(rootViewController: poster)

        prepareModalSheet(style: .formSheet)
        preferredContentSize.width *= 0.9
        preferredContentSize.height *= 0.7
        assert(!(poster.renoteId != nil && poster.replyId != nil))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        platformSetup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
