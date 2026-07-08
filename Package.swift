// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ChattySDK",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "ChattySDK", targets: ["ChattySDK"])
    ],
    targets: [
        .target(name: "ChattySDK", path: "Sources/ChattySDK")
    ]
)
