// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-parsing-dump",
    platforms: [
      .iOS(.v13),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        .library(
            name: "ParsingDump",
            targets: ["ParsingDump"]),
    ],
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.9.0"),
      .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "ParsingDump",
            dependencies: [
              .product(name: "Parsing", package: "swift-parsing"),
              .product(name: "CustomDump", package: "swift-custom-dump"),
            ]),
        .testTarget(
            name: "ParsingDumpTests",
            dependencies: ["ParsingDump"]),
    ]
)
