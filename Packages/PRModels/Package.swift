// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRModels",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRModels",
            targets: ["PRModels"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
    ],
    targets: [
        .target(
            name: "PRModels",
            dependencies: ["PRCore"],
            path: "Sources/PRModels"
        ),
    ]
)
