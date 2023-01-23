//
//  ToolItemButton.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit

extension PostEditorToolbarView {
    static let toolItemSize: CGFloat = 22
    static let spacing: CGFloat = 16
    static let preferredHeight: CGFloat = toolItemSize + spacing * 2

    class ToolItemButton: UIButton {
        typealias PostEditAction = (
            _ post: Post,
            _ anchor: UIView
        ) -> Void

        struct MenuItem {
            let icon: UIImage?
            let text: String
            let action: PostEditAction

            init(icon: UIImage? = nil, text: String = "", action: @escaping PostEditorToolbarView.ToolItemButton.PostEditAction) {
                self.icon = icon
                self.text = text
                self.action = action
            }
        }

        let post: Post

        let toolMenu: [MenuItem]
        let toolIcon: (Post) -> (UIImage)
        let toolEnabled: (Post) -> (Bool)

        let contextMenuPreviewRef = UIView()

        init(
            post: Post,
            toolMenu: [MenuItem?],
            toolIcon: @escaping (Post) -> (UIImage),
            toolEnabled: @escaping (Post) -> Bool
        ) {
            self.post = post
            self.toolMenu = toolMenu.compactMap { $0 }
            self.toolIcon = toolIcon
            self.toolEnabled = toolEnabled

            super.init(frame: .zero)
            imageView?.contentMode = .scaleAspectFit
            addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

            addSubview(contextMenuPreviewRef)
            contextMenuPreviewRef.frame = CGRect(x: 0, y: 0, width: 0, height: 0)

            let interaction = UIContextMenuInteraction(delegate: self)
            addInteraction(interaction)

            updateAppearance()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func updateAppearance() {
            setImage(toolIcon(post), for: .normal)
            isEnabled = toolEnabled(post)
        }

        @objc func buttonTapped() {
            if toolMenu.count == 0 { return }
            HapticGenerator.make(.selectionChanged)
            if toolMenu.count == 1 {
                toolMenu[0].action(post, self)
            } else {
                presentMenu()
            }
        }

        override func contextMenuInteraction(_: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration _: UIContextMenuConfiguration) -> UITargetedPreview? {
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .platformBackground
            parameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 0, height: 0), cornerRadius: 0)
            let preview = UITargetedPreview(view: contextMenuPreviewRef, parameters: parameters)
            return preview
        }

        override func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            let actions: [UIAction] = toolMenu.map { menuItem in
                .init(title: menuItem.text, image: menuItem.icon) { [weak self] _ in
                    guard let self else { return }
                    menuItem.action(self.post, self)
                    self.isEnabled = self.toolEnabled(self.post)
                }
            }
            let menu = UIMenu(children: actions)
            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: nil
            ) { _ in menu }
        }
    }
}
