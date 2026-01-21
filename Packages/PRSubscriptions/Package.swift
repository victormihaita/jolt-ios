// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRSubscriptions",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRSubscriptions",
            targets: ["PRSubscriptions"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "PRSubscriptions",
            dependencies: [
                "PRCore",
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "RevenueCatUI", package: "purchases-ios"),
            ],
            path: "Sources/PRSubscriptions"
        ),
    ]
)
