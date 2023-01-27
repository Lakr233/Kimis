//
//  Network+NMInstance.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import BetterCodable
import Foundation

public struct NMInstance: Codable {
    @LossyOptional public var uri: String?

    @LossyOptional public var name: String?
    @LossyOptional public var description: String?
    @LossyOptional public var version: String?

    @LossyOptional public var softwareName: String?
    @LossyOptional public var softwareVersion: String?

    @LossyOptional public var iconUrl: String?
    @LossyOptional public var faviconUrl: String?
    @LossyOptional public var themeColor: String?
    @LossyOptional public var bannerUrl: String?
    @LossyOptional public var backgroundImageUrl: String?

    @LossyOptional public var tosUrl: String?
    @LossyOptional public var maintainerName: String?
    @LossyOptional public var maintainerEmail: String?

    @LossyOptional public var emojis: [NMEmoji]?

    @LossyOptional public var features: [String: Bool]?

    @LossyOptional public var maxNoteTextLength: Int?
}
