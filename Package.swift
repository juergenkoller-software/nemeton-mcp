// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NemetonMCP",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NemetonMCP", targets: ["NemetonMCP"])
    ],
    targets: [
        .executableTarget(
            name: "NemetonMCP",
            path: "Sources/NemetonMCP"
        )
    ]
)
