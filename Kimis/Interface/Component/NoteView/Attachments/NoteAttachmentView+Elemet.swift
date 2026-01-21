//
//  NoteAttachmentView+Elemet.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/20.
//

import Foundation

extension NoteAttachmentView {
    struct Elemet: Equatable, Hashable {
        let id: String
        let name: String
        let url: URL
        let contentType: String
        let contentSize: Int
        let previewSize: CGSize?
        let previewBlur: String?
        let sensitive: Bool

        init(id: String, name: String, url: URL, contentType: String, contentSize: Int, previewSize: CGSize? = nil, previewBlur: String? = nil, sensitive: Bool) {
            self.id = id
            self.name = name
            self.url = url
            self.contentType = contentType
            self.contentSize = contentSize
            self.previewSize = previewSize
            self.previewBlur = previewBlur
            self.sensitive = sensitive
        }

        init(with attachment: Attachment) {
            var previewSize: CGSize?
            if let width = attachment.preferredWidth,
               let height = attachment.preferredHeight
            {
                previewSize = .init(width: width, height: height)
            }
            self.init(
                id: attachment.attachId,
                name: attachment.name,
                url: attachment.url,
                contentType: attachment.contentType,
                contentSize: attachment.contentSize,
                previewSize: previewSize,
                previewBlur: attachment.previewBlurHash,
                sensitive: attachment.isSensitive,
            )
        }
    }
}
