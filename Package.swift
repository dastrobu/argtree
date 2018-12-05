// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "argtree",
    products: [
        .library(
            name: "argtree",
            targets: [
                "argtree"
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", from: "1.8.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.8.0")
    ],
    targets: [
        .target(
            name: "argtree",
            dependencies: [
                "LoggerAPI",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "argtreeTests",
            dependencies: [
                "argtree",
                "HeliumLogger",
            ]),
    ]
)
