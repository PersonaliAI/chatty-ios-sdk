# Chatty iOS SDK

**Native SwiftUI chat UI for [Chatty](https://github.com/PersonaliAI/chatty) — no WebView.**

Drop a fully native, on-brand support chat into any iOS app. The SDK talks directly to the same
`/api/widget/*` backend as the Chatty web widget and renders every message, bubble, and composer
with real SwiftUI views — no WKWebView, no JS bridge.

[![CI](https://github.com/PersonaliAI/chatty-ios-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/PersonaliAI/chatty-ios-sdk/actions/workflows/ci.yml)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](#install)
[![CocoaPods](https://img.shields.io/cocoapods/v/ChattySDK.svg)](https://cocoapods.org/pods/ChattySDK)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![iOS 15+](https://img.shields.io/badge/iOS-15%2B-lightgrey.svg)](#requirements)

> **Status:** developed and code-reviewed in an environment without an Xcode/swiftc toolchain, so
> it has never been compiled locally. [`ci.yml`](.github/workflows/ci.yml) runs `swift build` /
> `swift test` on macOS runners on every push — check that it's green before relying on a
> pre-release build, and please open an issue if it isn't.

---

## Contents

- [Why this SDK](#why-this-sdk)
- [Install](#install)
- [Quick start](#quick-start)
- [Design parity](#design-parity)
- [API reference](#api-reference)
- [Example app](#example-app)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Why this SDK

- **No WebView.** Every bubble, avatar, and the composer are real SwiftUI views — no iframe, no
  JS bridge, no WKWebView overhead.
- **Matches your dashboard design automatically.** Whatever one of the 10 Chatty widget designs
  is selected for the bot, the SDK fetches the theme and renders with matching colors and corner
  radii. See [Design parity](#design-parity).
- **Two integration shapes.** A floating [`ChattyLauncher`](#chattylauncher) button + sheet, or
  an embedded [`ChattyChatView`](#chattychatview) you place directly in your own view hierarchy.
- **Zero third-party dependencies.** Only Apple's own SwiftUI, PhotosUI, and Foundation.

## Install

### Swift Package Manager (recommended)

In Xcode: **File → Add Package Dependencies…** and enter:

```
https://github.com/PersonaliAI/chatty-ios-sdk
```

Or add it to `Package.swift` directly:

```swift
dependencies: [
    .package(url: "https://github.com/PersonaliAI/chatty-ios-sdk", from: "1.0.3")
]
```

### CocoaPods

```ruby
pod 'ChattySDK', '~> 1.0.3'
```

## Quick start

Find your bot ID in the Chatty dashboard under **Embed & Integrate → iOS SDK**.

### Floating launcher (recommended)

A button that expands into a chat sheet — the native equivalent of the web widget's launcher.

```swift
import ChattySDK

struct RootView: View {
    var body: some View {
        ContentView()
            .overlay(ChattyLauncher(botId: "YOUR_BOT_ID"))
    }
}
```

### Embedded full-screen chat

Place the chat directly in your own navigation — e.g. as a "Support" tab.

```swift
import ChattySDK

struct SupportScreen: View {
    var body: some View {
        ChattyChatView(botId: "YOUR_BOT_ID")
    }
}
```

## Design parity

The SDK ships all 10 Chatty widget designs as SwiftUI color/radius tokens, ported 1:1 from the
web widget's `globals.css`, so a native screen looks like the design chosen in the dashboard
rather than one generic look:

`minimal` · `playful` · `corporate` · `dark-sleek` · `gradient-glow` · `glassmorphism` ·
`ecommerce` · `healthcare-calm` · `neubrutalism` · `luxury-editorial`

No configuration is required — `ChattyChatView` fetches the bot's theme and resolves the
matching token set automatically, including legacy `widget_style` IDs from older presets. Font
pairing (each web design uses a distinct Google Font) is intentionally out of scope for this
release; color, radius, and header/bubble treatment carry most of a design's identity.

## API reference

### `ChattyLauncher`

```swift
public init(
    botId: String,
    baseURL: String = chattyDefaultBaseURL,
    host: String? = nil,
    position: ChattyPosition = .bottomTrailing,
    color: Color? = nil
)
```

| Param | Description |
|---|---|
| `botId` | **Required.** Your bot's ID from the dashboard. |
| `baseURL` | Chatty backend base URL. Defaults to the production API. |
| `host` | Advisory only — sent to the backend but not used for access control. See [Notes](#notes). |
| `position` | `.bottomLeading` or `.bottomTrailing`. Default `.bottomTrailing`. |
| `color` | Overrides the launcher color. Defaults to the active design's accent color. |

### `ChattyChatView`

```swift
public init(
    botId: String,
    baseURL: String = chattyDefaultBaseURL,
    host: String? = nil,
    onMessage: ((ChattyMessage) -> Void)? = nil
)
```

| Param | Description |
|---|---|
| `botId` | **Required.** Your bot's ID from the dashboard. |
| `baseURL` | Chatty backend base URL. Defaults to the production API. |
| `host` | Advisory only — sent to the backend but not used for access control. See [Notes](#notes). |
| `onMessage` | Called for every inbound message — useful for unread badges or analytics. |

### Notes

- **`bot_id` is not a secret** — it's extractable from any client, web or mobile. Domain
  restriction (`allowed_domains` in the dashboard) is enforced by the backend as a **rate-limit
  tier**, not a hard reject: verified web traffic gets 30 msgs/60s per bot+IP, everything else
  (including all mobile SDK traffic — there's no way for a native app to obtain a "verified"
  token the way a browser's `Referer` allows) gets throttled to 5 msgs/120s. The `host` param
  this SDK sends is advisory only and isn't used for access control. If your bot is
  mobile-primary, leave `allowed_domains` empty to get the normal 30/60s tier instead.
- Lead capture and meeting booking happen conversationally (the assistant decides to ask/act) —
  there's no separate REST call to trigger them from the SDK.
- Polling for human-agent takeover messages runs every 4s while `ChattyChatView` is active,
  matching the web widget's behavior.
- Conversation history is persisted locally (`UserDefaults`), mirroring the web widget's
  `localStorage` cache, so a returning user sees their prior messages.

## Example app

[`Example/ChattySDKExample.xcodeproj`](Example) is a minimal, runnable SwiftUI app demonstrating
both integration styles side by side. Open it in Xcode (it resolves `ChattySDK` as a local Swift
Package pointing at the repo root) and run on a simulator to try the floating launcher and the
embedded full-screen chat against a live demo bot.

## Requirements

- iOS 15+ (macOS 13+ for the library target)
- Swift 5.7+, SwiftUI
- Uses `async`/`await`, `@StateObject` — no third-party dependencies
- **Add these keys to your app's `Info.plist`** to use the composer's mic and camera
  buttons (a library target can't inject `Info.plist` entries — this has to be in the
  consuming app):
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>Used to record voice messages in chat.</string>
  <key>NSCameraUsageDescription</key>
  <string>Used to attach photos in chat.</string>
  ```
  Without these, tapping the mic/camera silently does nothing (iOS kills the process on
  a missing usage string rather than showing an error).

## Contributing

Bug reports, design-parity fixes, and PRs are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)
for local setup and project structure.

## License

[MIT](LICENSE) © PersonaliAI
