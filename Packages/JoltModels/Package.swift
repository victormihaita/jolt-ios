// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltModels",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltModels",
            targets: ["JoltModels"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
    ],
    targets: [
        .target(
            name: "JoltModels",
            dependencies: ["JoltCore"],
            path: "Sources/JoltModels"
        ),
    ]
)
