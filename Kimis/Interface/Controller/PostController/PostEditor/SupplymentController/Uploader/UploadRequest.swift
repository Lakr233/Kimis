//
//  UploadRequest.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/11.
//

import Combine
import UIKit

extension AttachUploadController {
    class UploadRequest: Identifiable, Hashable, Equatable {
        var id: Int { hashValue }
        weak var source: Source? = Account.shared.source

        let assetFile: URL

        enum Status {
            case pending
            case uploading
            case done
            case failed(error: String)
        }

        var status: Status {
            if attachment?.attachId != nil { return .done }
            if let error { return .failed(error: error) }
            if associatedUrlTask != nil { return .uploading }
            return .pending
        }

        var error: String? {
            didSet { updated.send(true) }
        }

        var progress: Double = 0 {
            didSet { updated.send(true) }
        }

        var attachment: Attachment? {
            didSet { updated.send(true) }
        }

        var completed: Bool { attachment?.attachId != nil }

        let updated = CurrentValueSubject<Bool, Never>(true)

        var associatedUrlTask: URLSessionDataTask?

        init(assetFile: URL, progress: Double = 0, attachment: Attachment? = nil) {
            self.assetFile = assetFile
            self.progress = progress
            self.attachment = attachment
            updated.send(true)
        }

        static func == (lhs: UploadRequest, rhs: UploadRequest) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(assetFile)
            hasher.combine(progress)
            hasher.combine(attachment)
        }
    }
}

extension AttachUploadController.UploadRequest {
    func startUploading(sem: DispatchSemaphore? = nil) {
        guard let source else { return }

        guard !completed, associatedUrlTask == nil else {
            print("[*] \(#function) already completed or task exists, skip start request")
            return
        }
        let url = assetFile
        error = nil
        progress = 0
        print("[*] \(#function) \(url) \(status) \(progress)")

        DispatchQueue.global().async {
            sem?.wait()
            defer { sem?.signal() }

            let attachment = source.req.requestDriveFileCreate(asset: url, setTask: { task in
                self.associatedUrlTask = task
            }, setProgress: { progress in
                self.progress = progress
            })
            withMainActor {
                self.associatedUrlTask = nil
                self.progress = attachment == nil ? 0 : 1
                self.attachment = attachment
                self.error = attachment == nil ? "" : nil
            }
        }
    }

    func cancelUpload() {
        if let task = associatedUrlTask { task.cancel() }
        associatedUrlTask = nil
    }
}

extension AttachUploadController.UploadRequest.Status {
    var title: String {
        switch self {
        case .pending: "Pending"
        case .uploading: "Uploading"
        case .done: "Uploaded"
        case .failed: "Failed"
        }
    }

    var color: UIColor? {
        switch self {
        case .failed: .systemPink
        default: nil
        }
    }

    var icon: UIImage? {
        switch self {
        case .done: .init(systemName: "checkmark.circle.fill")
        case .failed: .init(systemName: "xmark.circle.fill")
        default: nil
        }
    }

    var iconColor: UIColor {
        switch self {
        case .failed: .systemPink
        default: .accent
        }
    }
}
