// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRNetworking",
            targets: ["PRNetworking"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
        .package(path: "../PRKeychain"),
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "PRNetworking",
            dependencies: [
                "PRCore",
                "PRKeychain",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloWebSocket", package: "apollo-ios"),
                .product(name: "ApolloSQLite", package: "apollo-ios"),
            ],
            path: "Sources/PRNetworking"
        ),
        .testTarget(
            name: "PRNetworkingTests",
            dependencies: ["PRNetworking"],
            path: "Tests/PRNetworkingTests"
        ),
    ]
)
