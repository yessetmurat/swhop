// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "swhop",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(name: "swhop", dependencies: ["TOMLKit"]),
    ]
)
