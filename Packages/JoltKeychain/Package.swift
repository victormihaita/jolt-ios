// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoltKeychain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "JoltKeychain",
            targets: ["JoltKeychain"]
        ),
    ],
    dependencies: [
        .package(path: "../JoltCore"),
    ],
    targets: [
        .target(
            name: "JoltKeychain",
            dependencies: ["JoltCore"],
            path: "Sources/JoltKeychain"
        ),
    ]
)
