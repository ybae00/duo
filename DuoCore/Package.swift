// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DuoCore",
    products: [
        .library(name: "DuoCore", targets: ["DuoCore"])
    ],
    targets: [
        .target(name: "DuoCore"),
        .testTarget(name: "DuoCoreTests", dependencies: ["DuoCore"]),
    ]
)
