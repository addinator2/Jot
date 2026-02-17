// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "jot",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1"),
    ],
    targets: [
        .target(name: "JotKit", path: "Sources/JotKit"),
        .executableTarget(
            name: "jot",
            dependencies: ["JotKit", "HotKey"],
            path: "Sources/jot"
        ),
        .testTarget(
            name: "JotKitTests",
            dependencies: ["JotKit"]
        ),
    ]
)
