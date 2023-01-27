//
//  Network+NMDriveFile.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/1.
//

import BetterCodable
import Foundation

public struct NMDriveFile: Codable {
    public var id: String
    @LossyOptional public var createdAt: String?
    public var name: String
    public var type: String
    @LossyOptional public var md5: String?
    @LossyOptional public var size: Int?
    public var isSensitive: Bool
    @LossyOptional public var blurhash: String?
    @LossyOptional public var properties: NMProperties?
    public var url: String
    @LossyOptional public var thumbnailUrl: String?
    @LossyOptional public var comment: String?
    @LossyOptional public var folderId: String?
    @LossyOptional public var userId: String?
//        @LossyOptional public var folder: NMUserLiteFolder?
    @LossyOptional public var user: NMUserLite?
}

public struct NMProperties: Codable {
    @LossyOptional public var height: Int?
    @LossyOptional public var width: Int?
    @LossyOptional public var orientation: Int?
    @LossyOptional public var avgColor: String?
}
