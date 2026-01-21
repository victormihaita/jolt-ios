// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRDesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRDesignSystem",
            targets: ["PRDesignSystem"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
    ],
    targets: [
        .target(
            name: "PRDesignSystem",
            dependencies: ["PRCore"],
            path: "Sources/PRDesignSystem"
        ),
    ]
)
