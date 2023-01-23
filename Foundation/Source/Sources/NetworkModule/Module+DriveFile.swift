//
//  Network+NMDriveFile.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/1.
//

import Foundation

public struct NMDriveFile: Codable {
    public var id: String
    public var createdAt: String?
    public var name: String
    public var type: String
    public var md5: String?
    public var size: Int?
    public var isSensitive: Bool
    public var blurhash: String?
    public var properties: NMProperties?
    public var url: String
    public var thumbnailUrl: String?
    public var comment: String?
    public var folderId: String?
    public var userId: String?
//        public var folder: NMUserLiteFolder?
    public var user: NMUserLite?
}

public struct NMProperties: Codable {
    public var height: Int?
    public var width: Int?
    public var orientation: Int?
    public var avgColor: String?
}
