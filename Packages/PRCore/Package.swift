// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRCore",
            targets: ["PRCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PRCore",
            dependencies: [],
            path: "Sources/PRCore"
        ),
    ]
)
