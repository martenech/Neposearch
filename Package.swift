// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Neposearch",
    platforms: [.macOS("26.0")],
    dependencies: [
        .package(url: "https://github.com/objectbox/objectbox-swift-spm.git", from: "5.3.0"),
        .package(url: "https://github.com/jkrukowski/swift-embeddings", from: "0.1.1"),
    ],
    targets: [
        .executableTarget(
            name: "Neposearch",
            dependencies: [
                .product(name: "ObjectBox.xcframework", package: "objectbox-swift-spm"),
                .product(name: "Embeddings", package: "swift-embeddings"),
            ],
            exclude: ["model-Neposearch.json", "model-Neposearch.json.bak"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
