//
//  Network+NMInstance.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import Foundation

public struct NMInstance: Codable {
    public var uri: String?

    public var name: String?
    public var description: String?
    public var version: String?

    public var softwareName: String?
    public var softwareVersion: String?

    public var iconUrl: String?
    public var faviconUrl: String?
    public var themeColor: String?
    public var bannerUrl: String?
    public var backgroundImageUrl: String?

    public var tosUrl: String?
    public var maintainerName: String?
    public var maintainerEmail: String?

    public var emojis: [NMEmoji]?

    public var features: [String: Bool]?

    public var maxNoteTextLength: Int?
}
