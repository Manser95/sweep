// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sweep",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Sweep",
            path: "Sources/Sweep",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
