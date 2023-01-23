//
//  Instance.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import Foundation
import Module
import NetworkModule

public extension Instance {
    static func converting(_ object: NMInstance) -> Instance? {
        var featureSet = [Feature: Bool]()
        for (key, value) in object.features ?? [:] {
            if let key = Feature(rawValue: key) {
                featureSet[key] = value
            }
        }
        return Instance(
            uri: object.uri,
            name: object.name ?? "",
            description: object.description ?? "",
            version: object.version ?? "",
            softwareName: object.softwareName ?? "",
            softwareVersion: object.softwareVersion ?? "",
            iconUrl: object.iconUrl,
            faviconUrl: object.faviconUrl,
            themeColor: object.themeColor,
            bannerUrl: object.bannerUrl,
            backgroundImageUrl: object.backgroundImageUrl,
            tosUrl: object.tosUrl,
            maintainerName: object.maintainerName ?? "",
            maintainerEmail: object.maintainerEmail ?? "",
            features: featureSet,
            maxNoteTextLength: object.maxNoteTextLength ?? 3000
        )
    }
}
