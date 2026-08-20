// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ChattySDK",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        // Explicit `.dynamic` (rather than the default "automatic") so
        // `xcodebuild archive` actually emits a Frameworks/ChattySDK.framework
        // bundle for XCFramework release packaging — "automatic" resolves to
        // a static archive with no framework bundle when SKIP_INSTALL=NO.
        .library(name: "ChattySDK", type: .dynamic, targets: ["ChattySDK"])
    ],
    targets: [
        .target(name: "ChattySDK", path: "Sources/ChattySDK")
    ]
)
