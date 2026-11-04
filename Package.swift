// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swhop",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0"),
    ],
    targets: [
        .target(name: "SwhopCore", dependencies: ["TOMLKit"], path: "Sources/core"),
        .executableTarget(
            name: "swhop",
            dependencies: ["SwhopCore"],
            // The panel keeps its state in globals, which Swift 6 mode rejects.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "SwhopCoreTests", dependencies: ["SwhopCore"]),
    ]
)
