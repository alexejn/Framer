// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Framer",
    platforms: [
        .macOS("13.0"),
        .iOS("16.0"),
        .macCatalyst("16.0")
    ],
    products: [
        .library(
            name: "Framer",
            targets: ["Framer"]),
    ],
    dependencies: [
    ],
    targets: [ 
        .target(
            name: "Framer",
            dependencies: [],
            path: "Sources"),
        
        .testTarget(
            name: "FramerTests",
            dependencies: ["Framer"]),
    ]
)
