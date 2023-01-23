//
//  Attachment.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/26.
//

import Foundation
import Module
import NetworkModule

public extension Attachment {
    static func converting(_ object: NMDriveFile) -> Attachment? {
        guard let url = URL(string: object.url)
        else {
            return nil
        }
        return .init(
            attachId: object.id,
            name: object.name,
            user: object.userId ?? "",
            url: url,
            contentType: object.type,
            contentSize: object.size ?? 0,
            previewBlurHash: object.blurhash ?? "",
            preferredWidth: object.properties?.width,
            preferredHeight: object.properties?.height,
            isSensitive: object.isSensitive
        )
    }
}
