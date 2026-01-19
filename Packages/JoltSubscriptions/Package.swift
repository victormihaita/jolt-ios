// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltSubscriptions",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltSubscriptions",
            targets: ["JoltSubscriptions"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "JoltSubscriptions",
            dependencies: [
                "JoltCore",
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "RevenueCatUI", package: "purchases-ios"),
            ],
            path: "Sources/JoltSubscriptions"
        ),
    ]
)
