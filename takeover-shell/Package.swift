// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "takeover-shell",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "takeover-shell",
            dependencies: ["Yams"],
            path: "Sources"
        )
    ]
)
