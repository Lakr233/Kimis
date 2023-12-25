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
            .init(icon: .fluent(.globe_person_filled), text: "Public", action: { post, _ in
                post.visibility = .public
            }),
            .init(icon: .fluent(.checkbox_person_filled), text: "Followers", action: { post, _ in
                post.visibility = .followers
            }),
            .init(icon: .fluent(.home_person_filled), text: "Local", action: { post, _ in
                post.visibility = .home
            }),
            // TODO: mail to target
        ], toolIcon: { post in
            switch post.visibility {
            case .public: return .fluent(.globe_person_filled)
            case .followers: return .fluent(.checkbox_person_filled)
            case .home: return .fluent(.home_person_filled)
            case .specified: return .fluent(.person_mail_filled)
            }
        }, toolEnabled: { _ in
            true
        }),
    ] }
}
