// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRNotifications",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRNotifications",
            targets: ["PRNotifications"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
        .package(path: "../PRModels"),
    ],
    targets: [
        .target(
            name: "PRNotifications",
            dependencies: ["PRCore", "PRModels"],
            path: "Sources/PRNotifications"
        ),
    ]
)
