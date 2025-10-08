//
//  Toolbar+Visibility.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit

extension PostEditorToolbarView {
    func createButtonsForVisibility() -> [ToolItemButton] { [
        ToolItemButton(post: post, toolMenu: [
            .init(icon: .fluent(.globe_person_filled), text: L10n.text("Public"), action: { post, _ in
                post.visibility = .public
            }),
            .init(icon: .fluent(.checkbox_person_filled), text: L10n.text("Followers"), action: { post, _ in
                post.visibility = .followers
            }),
            .init(icon: .fluent(.home_person_filled), text: L10n.text("Local"), action: { post, _ in
                post.visibility = .home
            }),
            // TODO: mail to target
        ], toolIcon: { post in
            switch post.visibility {
            case .public: .fluent(.globe_person_filled)
            case .followers: .fluent(.checkbox_person_filled)
            case .home: .fluent(.home_person_filled)
            case .specified: .fluent(.person_mail_filled)
            }
        }, toolEnabled: { _ in
            true
        }),
    ] }
}
