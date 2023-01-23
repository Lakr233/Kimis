//
//  Instance.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import Foundation

public class Instance: Codable, Identifiable, Hashable, Equatable {
    public var id: String { uri ?? UUID().uuidString }

    public var uri: String?
    public var name: String
    public var description: String
    public var version: String

    public var softwareName: String
    public var softwareVersion: String

    public var iconUrl: String?
    public var faviconUrl: String?
    public var themeColor: String?
    public var bannerUrl: String?
    public var backgroundImageUrl: String?

    public var tosUrl: String?
    public var maintainerName: String
    public var maintainerEmail: String

    public var features: [Feature: Bool]
    public var maxNoteTextLength: Int

    public init(uri: String?, name: String, description: String, version: String, softwareName: String, softwareVersion: String, iconUrl: String?, faviconUrl: String?, themeColor: String?, bannerUrl: String?, backgroundImageUrl: String?, tosUrl: String?, maintainerName: String, maintainerEmail: String, features: [Instance.Feature: Bool], maxNoteTextLength: Int) {
        self.name = name
        self.description = description
        self.version = version
        self.uri = uri
        self.softwareName = softwareName
        self.softwareVersion = softwareVersion
        self.iconUrl = iconUrl
        self.faviconUrl = faviconUrl
        self.themeColor = themeColor
        self.bannerUrl = bannerUrl
        self.backgroundImageUrl = backgroundImageUrl
        self.tosUrl = tosUrl
        self.maintainerName = maintainerName
        self.maintainerEmail = maintainerEmail
        self.features = features
        self.maxNoteTextLength = maxNoteTextLength
    }

    public convenience init() {
        self.init(uri: nil, name: "", description: "", version: "", softwareName: "", softwareVersion: "", iconUrl: nil, faviconUrl: nil, themeColor: nil, bannerUrl: nil, backgroundImageUrl: nil, tosUrl: nil, maintainerName: "", maintainerEmail: "", features: [:], maxNoteTextLength: 3000)
    }

    public enum Feature: String, Codable {
        case registration
        case localTimeLine
        case globalTimeLine
        case emailRequiredForSignup
        case elasticsearch
        case hcaptcha
        case recaptcha
        case objectStorage
        case twitter
        case github
        case discord
        case serviceWorker
        case miauth
    }

    public static func == (lhs: Instance, rhs: Instance) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(version)
        hasher.combine(softwareName)
        hasher.combine(softwareVersion)
        hasher.combine(iconUrl)
        hasher.combine(faviconUrl)
        hasher.combine(themeColor)
        hasher.combine(bannerUrl)
        hasher.combine(backgroundImageUrl)
        hasher.combine(tosUrl)
        hasher.combine(maintainerName)
        hasher.combine(maintainerEmail)
        hasher.combine(features)
        hasher.combine(maxNoteTextLength)
    }
}
