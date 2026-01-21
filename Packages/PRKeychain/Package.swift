// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PRKeychain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "PRKeychain",
            targets: ["PRKeychain"]
        ),
    ],
    dependencies: [
        .package(path: "../PRCore"),
    ],
    targets: [
        .target(
            name: "PRKeychain",
            dependencies: ["PRCore"],
            path: "Sources/PRKeychain"
        ),
    ]
)
