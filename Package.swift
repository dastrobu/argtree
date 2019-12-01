// swift-tools-version:4.0

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
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "argtree",
            dependencies: [
                "Logging",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "argtreeTests",
            dependencies: [
                "argtree",
            ]),
    ]
)
