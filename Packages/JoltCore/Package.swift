// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltCore",
            targets: ["JoltCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JoltCore",
            dependencies: [],
            path: "Sources/JoltCore"
        ),
    ]
)
