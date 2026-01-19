// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltDesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltDesignSystem",
            targets: ["JoltDesignSystem"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
    ],
    targets: [
        .target(
            name: "JoltDesignSystem",
            dependencies: ["JoltCore"],
            path: "Sources/JoltDesignSystem"
        ),
    ]
)
