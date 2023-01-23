//
//  Toolbar+Cloud.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/12.
//

import UIKit

extension PostEditorToolbarView {
    func createButtonsForCloudDrive() -> [ToolItemButton] { [
        ToolItemButton(post: post, toolMenu: [
            .init(icon: .init(systemName: "cloud"), text: "Drive File", action: { post, _ in
                let controller = AttachmentDrivePicker(post: post)
                self.insertViewController(controller)
            }),
        ], toolIcon: { _ in
            UIImage.fluent(.cloud_checkmark_filled)
        }, toolEnabled: {
            $0.attachments.count <= 32
        }),
    ] }
}
