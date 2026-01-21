// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRSync",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRSync",
            targets: ["PRSync"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
        .package(path: "../PRModels"),
        .package(path: "../PRNetworking"),
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "PRSync",
            dependencies: [
                "PRCore",
                "PRModels",
                "PRNetworking",
                .product(name: "Apollo", package: "apollo-ios"),
            ],
            path: "Sources/PRSync"
        ),
    ]
)
