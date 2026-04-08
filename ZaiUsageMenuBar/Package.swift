// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZaiUsageMenuBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ZaiUsageMenuBar",
            path: "Sources/ZaiUsageMenuBar",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "ZaiUsageMenuBarTests",
            dependencies: ["ZaiUsageMenuBar"],
            path: "Tests/ZaiUsageMenuBarTests"
        )
    ]
)
