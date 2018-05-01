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
    ],
    targets: [
        .target(
            name: "argtree",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "argtreeTests",
            dependencies: [
                "argtree",
            ]),
    ]
)
