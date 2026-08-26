// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Focenda",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FocendaCore",
            targets: ["FocendaCore"]
        ),
        .executable(
            name: "FocendaApp",
            targets: ["FocendaApp"]
        )
    ],
    targets: [
        .target(
            name: "FocendaCore"
        ),
        .executableTarget(
            name: "FocendaApp",
            dependencies: ["FocendaCore"]
        ),
        .testTarget(
            name: "FocendaTests",
            dependencies: ["FocendaCore"]
        )
    ]
)
