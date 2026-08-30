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
        .library(name: "ChattySDK", type: .dynamic, targets: ["ChattySDK"]),
        // Separate product/target (not folded into ChattySDK itself) so the
        // LiveKit dependency — a large, WebRTC-based SDK — is only pulled in
        // by apps that actually add this product, not by every ChattySDK
        // consumer. SwiftPM has no "optional dependency" concept within a
        // single target the way Gradle's compileOnly or npm's
        // peerDependenciesMeta.optional do; a second target is the
        // equivalent split.
        .library(name: "ChattySDKVoice", type: .dynamic, targets: ["ChattySDKVoice"]),
    ],
    dependencies: [
        .package(url: "https://github.com/livekit/client-sdk-swift.git", from: "2.16.0"),
    ],
    targets: [
        .target(name: "ChattySDK", path: "Sources/ChattySDK"),
        .target(
            name: "ChattySDKVoice",
            dependencies: [
                "ChattySDK",
                .product(name: "LiveKit", package: "client-sdk-swift"),
            ],
            path: "Sources/ChattySDKVoice"
        ),
        .testTarget(name: "ChattySDKTests", dependencies: ["ChattySDK"], path: "Tests/ChattySDKTests")
    ]
)
