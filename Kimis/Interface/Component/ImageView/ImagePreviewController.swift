//
//  ImagePreviewController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/9.
//

import QuickLook
import SDWebImage
import UIKit

private let previewContentDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)
    .appendingPathComponent("Preview")

class ImagePreviewController: QLPreviewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    var imageData: Data? {
        didSet { prepareFile() }
    }

    var targetLocation: URL? {
        didSet { reloadData() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
    }

    deinit {
        debugPrint("\(#file) \(#function)")
        if let location = targetLocation {
            try? FileManager.default.removeItem(at: location)
        }
    }

    func prepareFile() {
        if let location = targetLocation {
            try? FileManager.default.removeItem(at: location)
        }
        targetLocation = nil
        reloadData()
        guard let data = imageData,
              let image = UIImage(data: data)
        else {
            return
        }
        try? FileManager.default.createDirectory(at: previewContentDirectory, withIntermediateDirectories: true)
        let tempLocation = previewContentDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(image.sd_imageFormat.possiblePathExtension)
        try? data.write(to: tempLocation, options: .atomic)
        guard FileManager.default.fileExists(atPath: tempLocation.path) else {
            presentError("Unable to Load Data")
            return
        }
        targetLocation = tempLocation
    }

    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        targetLocation == nil ? 0 : 1
    }

    func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
        targetLocation! as QLPreviewItem
    }
}

extension SDImageFormat {
    var possiblePathExtension: String {
        switch self {
        case .undefined: return ""
        case .JPEG: return "jpg"
        case .PNG: return "png"
        case .GIF: return "gif"
        case .TIFF: return "tiff"
        case .webP: return "webp"
        case .HEIC: return "heic"
        case .HEIF: return "heif"
        case .PDF: return "pdf"
        case .SVG: return "svg"
        default: return ""
        }
//        static const SDImageFormat SDImageFormatUndefined = -1;
//        static const SDImageFormat SDImageFormatJPEG      = 0;
//        static const SDImageFormat SDImageFormatPNG       = 1;
//        static const SDImageFormat SDImageFormatGIF       = 2;
//        static const SDImageFormat SDImageFormatTIFF      = 3;
//        static const SDImageFormat SDImageFormatWebP      = 4;
//        static const SDImageFormat SDImageFormatHEIC      = 5;
//        static const SDImageFormat SDImageFormatHEIF      = 6;
//        static const SDImageFormat SDImageFormatPDF       = 7;
//        static const SDImageFormat SDImageFormatSVG       = 8;
    }
}
