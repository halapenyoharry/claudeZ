// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeZ",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeZ",
            targets: ["ClaudeZ"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClaudeZ",
            dependencies: []
        ),
    ]
)