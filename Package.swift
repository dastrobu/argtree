// swift-tools-version:6.1

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
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "argtree",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
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
