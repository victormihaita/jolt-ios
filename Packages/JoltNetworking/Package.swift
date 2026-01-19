// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltNetworking",
            targets: ["JoltNetworking"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
        .package(path: "../JoltKeychain"),
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "JoltNetworking",
            dependencies: [
                "JoltCore",
                "JoltKeychain",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloWebSocket", package: "apollo-ios"),
                .product(name: "ApolloSQLite", package: "apollo-ios"),
            ],
            path: "Sources/JoltNetworking"
        ),
        .testTarget(
            name: "JoltNetworkingTests",
            dependencies: ["JoltNetworking"],
            path: "Tests/JoltNetworkingTests"
        ),
    ]
)
