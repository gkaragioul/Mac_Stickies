// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StickyNotesApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "StickyNotesApp", targets: ["StickyNotesApp"])
    ],
    targets: [
        .executableTarget(
            name: "StickyNotesApp",
            path: "Sources/StickyNotesApp"
        ),
        .testTarget(
            name: "StickyNotesAppTests",
            dependencies: ["StickyNotesApp"],
            path: "Tests/StickyNotesAppTests"
        )
    ]
)
