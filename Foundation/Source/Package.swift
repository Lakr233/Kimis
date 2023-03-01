// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let allAvailable: Range<Version> = Version(0, 0, 0) ..< Version(999, 999, 999)

let package = Package(
    name: "Source",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
        .macOS(.v10_15),
    ],
    products: [.library(name: "Source", targets: ["Source"])],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", allAvailable),
        .package(url: "https://github.com/malcommac/SwiftDate.git", allAvailable),
        .package(url: "https://github.com/marksands/BetterCodable.git", allAvailable),
    ],
    targets: [
        .target(name: "Source", dependencies: ["Network", "Storage"]),

        // requesting data goes into
        .target(name: "Network", dependencies: ["ModuleBridge"]),

        // save data and load from database goes into
        .target(name: "Storage", dependencies: [
            "ModuleBridge",
            "LRUCache",
            .product(name: "SQLite", package: "SQLite.swift"),
        ]),

        .target(name: "LRUCache"),

        // define
        .target(name: "Module", dependencies: ["SwiftDate"]),

        .target(name: "NetworkModule", dependencies: ["BetterCodable"]),

        .target(name: "ModuleBridge", dependencies: [
            "Module",
            "NetworkModule",
        ]),

        .testTarget(name: "SourceTest", dependencies: [
            "Source",
        ]),
    ]
)
