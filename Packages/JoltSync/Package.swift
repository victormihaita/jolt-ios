// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltSync",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltSync",
            targets: ["JoltSync"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
        .package(path: "../JoltModels"),
        .package(path: "../JoltNetworking"),
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "JoltSync",
            dependencies: [
                "JoltCore",
                "JoltModels",
                "JoltNetworking",
                .product(name: "Apollo", package: "apollo-ios"),
            ],
            path: "Sources/JoltSync"
        ),
    ]
)
