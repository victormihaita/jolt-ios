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
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "PRSubscriptions",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
                .product(name: "RevenueCatUI", package: "purchases-ios-spm"),
            ],
            path: "Sources/PRSubscriptions"
        ),
    ]
)
