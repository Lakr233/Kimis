//
//  Toolbar+File.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit
import UniformTypeIdentifiers

extension PostEditorToolbarView {
    func createButtonsForFileAttachments() -> [ToolItemButton] { [
        ToolItemButton(post: post, toolMenu: [
            .init(action: { _, anchor in
                let controller = UIDocumentPickerViewController(
                    forOpeningContentTypes: [UTType.item],
                    asCopy: true
                )
                controller.prepareModalSheet(style: .formSheet)
                controller.allowsMultipleSelection = true
                controller.delegate = self
                anchor.parentViewController?.present(controller, animated: true)
            }),
        ], toolIcon: { _ in
            UIImage.fluent(.folder_add_filled)
        }, toolEnabled: {
            $0.attachments.count <= 32
        }),
    ] }
}

extension PostEditorToolbarView: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let tempDir = temporaryDirectory
            .appendingPathComponent("DocumentPicker")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let newUrls = urls.compactMap { origin in
            let newUrl = tempDir
                .appendingPathComponent(origin.lastPathComponent)
            do {
                try? FileManager.default.removeItem(at: newUrl)
                try FileManager.default.copyItem(at: origin, to: newUrl)
            } catch {
                presentError(error)
            }
            return newUrl
        }
        controller.dismiss(animated: true) {
            self.resolveFilesAndUpload(at: newUrls)
        }
    }
}
