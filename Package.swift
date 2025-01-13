// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "reporter",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/christophhagen/BinaryCodable", from: "3.0.0"),
        .package(url: "https://github.com/Kitura/Swift-SMTP", from: "6.0.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "reporter",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "BinaryCodable", package: "BinaryCodable"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "SwiftSMTP", package: "Swift-SMTP"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
    ]
)
