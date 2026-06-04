// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PassGenerator",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PassGenerator",
            path: "Sources/PassGenerator"
        )
    ]
)
