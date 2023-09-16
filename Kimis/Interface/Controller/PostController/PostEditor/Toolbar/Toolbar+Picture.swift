//
//  Toolbar+Picture.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/10.
//

import UIKit

import AVKit
import Photos
import PhotosUI
import UniformTypeIdentifiers

extension PostEditorToolbarView {
    func createButtonsForPictureAttachment() -> [ToolItemButton] { [
        ToolItemButton(post: post, toolMenu: [
            .init(icon: .init(systemName: "camera"), text: "Camera") { _, anchor in
                AVCaptureDevice.requestAccess(for: .video) { _ in
                    withMainActor {
                        let ctrl = UIImagePickerController()
                        ctrl.allowsEditing = true
                        ctrl.sourceType = .camera
                        ctrl.mediaTypes = [UTType.movie.identifier, UTType.image.identifier]
                        ctrl.cameraCaptureMode = .photo
                        ctrl.delegate = self
                        anchor.parentViewController?.present(ctrl, animated: true)
                    }
                }
            },
            .init(icon: .init(systemName: "photo.on.rectangle"), text: "Photo Library", action: { _, anchor in
                var config = PHPickerConfiguration(photoLibrary: .shared())
                config.selectionLimit = 16
                let controller = PHPickerViewController(configuration: config)
                controller.delegate = self
                anchor.parentViewController?.present(controller, animated: true)
            }),
        ], toolIcon: { _ in
            UIImage.fluent(.camera_add_filled)
        }, toolEnabled: {
            $0.attachments.count <= 32
        }),
    ] }
}

extension PostEditorToolbarView: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    enum ImageError: Error {
        case CompressError
    }

    static func processJPEGImageData(_ image: UIImage) throws -> Data? {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw ImageError.CompressError
        }
        return data
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        var resolveCompleted = false
        var resolveCanceled = false

        let sem = DispatchSemaphore(value: 0)
        var urls = [URL]()
        picker.dismiss(animated: true) {
            guard !results.isEmpty else { return }
            DispatchQueue.global().async {
                var progressAlert: UIAlertController?
                if !resolveCompleted { withMainActor {
                    let alert = UIAlertController(title: "⏳", message: "Exporting selected items", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        resolveCanceled = true
                    })
                    self.parentViewController?.present(alert, animated: true)
                    progressAlert = alert
                } }
                sem.wait()
                guard !urls.isEmpty, !resolveCanceled else { return }
                withMainActor {
                    if let alert = progressAlert {
                        alert.dismiss(animated: true) {
                            self.resolveFilesAndUpload(at: urls)
                        }
                    } else {
                        self.resolveFilesAndUpload(at: urls)
                    }
                }
            }
        }

        DispatchQueue.global().async {
            defer {
                resolveCompleted = true
                sem.signal()
            }
            for item in results where !resolveCanceled {
                let provider = item.itemProvider
                let objectSem = DispatchSemaphore(value: 0)
                provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, _ in
                    defer { objectSem.signal() }
                    guard let origItemUrl = url else { return }
                    if let image = UIImage(contentsOfFile: origItemUrl.path) {
                        let tempDir = temporaryDirectory
                            .appendingPathComponent("PhotoLibrary")
                        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                        let tempFile = tempDir
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("jpeg")
                        try? Self.processJPEGImageData(image)?.write(to: tempFile)
                        urls.append(tempFile)
                    } else {
                        let tempDir = temporaryDirectory
                            .appendingPathComponent("Files")
                        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                        let tempFile = tempDir
                            .appendingPathComponent(origItemUrl.lastPathComponent)
                        try? FileManager.default.removeItem(at: tempFile)
                        try? FileManager.default.copyItem(at: origItemUrl, to: tempFile)
                        urls.append(tempFile)
                    }
                }
                objectSem.wait()
            }
            if !resolveCanceled, urls.count != results.count {
                presentError("\(urls.count - results.count) item(s) failed to load")
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            var itemUrl: URL?

            if itemUrl == nil,
               let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            {
                let tempDir = temporaryDirectory
                    .appendingPathComponent("Camera")
                try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                let tempFile = tempDir
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpeg")
                try? Self.processJPEGImageData(image)?.write(to: tempFile)
                itemUrl = tempFile
            }
            if itemUrl == nil,
               let url = info[.mediaURL] as? URL
            {
                itemUrl = url
            }

            guard let url = itemUrl, FileManager.default.fileExists(atPath: url.path) else {
                return
            }
            print("[*] image picker resolving media files at \(url)")

            self.resolveFilesAndUpload(at: [url])
        }
    }
}
