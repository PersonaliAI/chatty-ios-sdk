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
        // Pinned below 2.14.0, not `from: "2.16.0"` — every release from
        // 2.14.0 on declares swift-tools-version:6.1, which needs Xcode
        // 16.3+ to even resolve; this repo's CI/release workflows pin Xcode
        // 15.4 (confirmed the hard way: CI failed with "contains
        // incompatible tools version (6.1.0)" the first time this dependency
        // was added at 2.16.0). 2.13.0 is the last release still on
        // swift-tools-version:5.9 (Xcode 15.0+). Bumping past 2.13.x needs
        // bumping the pinned Xcode version in ci.yml/release.yml first.
        .package(url: "https://github.com/livekit/client-sdk-swift.git", .upToNextMinor(from: "2.13.0")),
        // LiveKit's own Package.swift depends on this (pinned the same way:
        // `from: "1.31.0"`) but only re-exports it as an *implicit* transitive
        // module for plain `swift build`. Xcode's build system — used by
        // `xcodebuild archive`, which is how release.yml actually builds this
        // package — requires every module a target uses (even transitively
        // through another package's binary/dynamic target) to be an explicit
        // product dependency, or archiving fails with "Missing package
        // product 'SwiftProtobuf'" even though `swift build` succeeds clean.
        // Confirmed via a real CI archive failure the first time
        // ChattySDKVoice was added.
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.31.0"),
    ],
    targets: [
        .target(name: "ChattySDK", path: "Sources/ChattySDK"),
        .target(
            name: "ChattySDKVoice",
            dependencies: [
                "ChattySDK",
                .product(name: "LiveKit", package: "client-sdk-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            path: "Sources/ChattySDKVoice"
        ),
        .testTarget(name: "ChattySDKTests", dependencies: ["ChattySDK"], path: "Tests/ChattySDKTests")
    ]
)
