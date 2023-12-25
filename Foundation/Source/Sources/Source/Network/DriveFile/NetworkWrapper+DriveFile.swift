//
//  NetworkWrapper+DriveFile.swift
//
//
//  Created by Lakr Aream on 2023/1/11.
//

import Foundation

public extension Source.NetworkWrapper {
    func requestDriveFiles(sinceId: String? = nil, untilId: String? = nil) -> [Attachment] {
        // folder support not planned
        guard let ctx else { return [] }
        let result = ctx.network.requestForDriveFiles(sinceId: sinceId, untilId: untilId)
        return result.compactMap {
            Attachment.converting($0)
        }
    }

    func requestDriveFileCreate(
        asset: URL,
        setTask: ((URLSessionDataTask) -> Void)? = nil,
        setProgress: ((Double) -> Void)? = nil
    ) -> Attachment? {
        guard let ctx else { return nil }
        let result = ctx.network.requestDriveFileCreate(asset: asset) { task in
            setTask?(task)
        } setProgress: { progress in
            setProgress?(progress)
        }
        if let file = result {
            return .converting(file)
        }
        return nil
    }

    func requestDriveFileUpdate(
        fileId: String,
        name: String? = nil,
        isSensitive: Bool? = nil,
        comment: String? = nil
    ) -> Attachment? {
        guard let ctx else { return nil }
        let result = ctx.network.requestDriveFileUpdate(
            fileId: fileId,
            folderId: nil,
            name: name,
            isSensitive: isSensitive,
            comment: comment
        )
        if let file = result {
            return .converting(file)
        }
        return nil
    }
}
