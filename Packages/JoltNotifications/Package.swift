// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltNotifications",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltNotifications",
            targets: ["JoltNotifications"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
        .package(path: "../JoltModels"),
    ],
    targets: [
        .target(
            name: "JoltNotifications",
            dependencies: ["JoltCore", "JoltModels"],
            path: "Sources/JoltNotifications"
        ),
    ]
)
