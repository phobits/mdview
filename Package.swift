// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MarkdownViewer",
    platforms: [.macOS(.v13)],
    dependencies: [
        // cmark-gfm, the CommonMark + GitHub Flavored Markdown reference parser
        // (the one GitHub itself renders with), packaged by the Swift project.
        .package(url: "https://github.com/swiftlang/swift-cmark.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "MarkdownViewerCore",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ]
        ),
        .executableTarget(
            name: "MarkdownViewer",
            dependencies: ["MarkdownViewerCore"]
        ),
        .executableTarget(
            name: "QuickLookPreview",
            dependencies: ["MarkdownViewerCore"],
            linkerSettings: [
                // App extension binaries enter through NSExtensionMain, not main
                .unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])
            ]
        ),
        .testTarget(
            name: "MarkdownViewerCoreTests",
            dependencies: ["MarkdownViewerCore"]
        ),
    ]
)
