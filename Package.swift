// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "pix-batch-convert",
    platforms: [
        .macOS(.v10_14),
    ],
    dependencies: [
        .package(url: "https://github.com/heestand-xyz/Carpaccio", from: "0.0.7"),
    ],
    targets: [
        .target(name: "pix-batch-convert", dependencies: ["Carpaccio"]),
    ]
)
