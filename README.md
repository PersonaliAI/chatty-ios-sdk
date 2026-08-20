<div align="center">

# Chatty iOS SDK

**Native SwiftUI chat UI for [Chatty](https://github.com/PersonaliAI/chatty) — zero WebView, zero compromise.**

Drop a fully native, on-brand support chat into any iOS app in minutes. Talks directly to the
same `/api/widget/*` backend as the Chatty web widget, and renders every bubble, avatar, and
composer with real SwiftUI views — no WKWebView, no JS bridge, no compromise on feel.

[![CI](https://github.com/PersonaliAI/chatty-ios-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/PersonaliAI/chatty-ios-sdk/actions/workflows/ci.yml)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](#install)
[![CocoaPods](https://img.shields.io/cocoapods/v/ChattySDK.svg)](https://cocoapods.org/pods/ChattySDK)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![iOS 15+](https://img.shields.io/badge/iOS-15%2B-lightgrey.svg?logo=apple&logoColor=white)](#requirements)
[![Stars](https://img.shields.io/github/stars/PersonaliAI/chatty-ios-sdk?style=social)](https://github.com/PersonaliAI/chatty-ios-sdk/stargazers)

[Install](#install) · [Quick start](#quick-start) · [Design gallery](#design-gallery) · [API reference](#api-reference) · [Example app](#example-app)

</div>

---

> [!NOTE]
> Developed and code-reviewed in an environment without an Xcode/swiftc toolchain, so changes
> are never compiled locally before pushing. [`ci.yml`](.github/workflows/ci.yml) runs
> `swift build` / `swift test` on real macOS runners on every push — check the badge above is
> green before relying on a pre-release build, and please open an issue if it isn't.

## Why this SDK

| | |
|---|---|
| **No WebView, anywhere** | Every bubble, avatar, and the composer are real SwiftUI views — no iframe, no JS bridge, no WKWebView overhead. |
| **Matches your dashboard automatically** | Fetches the bot's theme and renders with the exact colors, corner radii, and launcher shape chosen in the dashboard — no manual styling. |
| **Two integration shapes** | A floating [`ChattyLauncher`](#chattylauncher) button + sheet, or an embedded [`ChattyChatView`](#chattychatview) inside your own view hierarchy. |
| **A real composer, not a stub** | Emoji picker, animated attach menu (camera + photo library), and mic-to-text voice notes — built in, not bolted on. |
| **Zero third-party dependencies** | Only Apple's own SwiftUI, PhotosUI, AVFoundation, and Foundation. |

## Install

### Swift Package Manager *(recommended)*

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

<details>
<summary><strong>CocoaPods</strong></summary>

<br>

```ruby
pod 'ChattySDK', '~> 1.0.3'
```

</details>

## Quick start

Find your bot ID in the Chatty dashboard under **Embed & Integrate → iOS SDK**.

**Floating launcher** *(recommended)* — a button that expands into a chat sheet, the native
equivalent of the web widget's launcher:

```swift
import ChattySDK

struct RootView: View {
    var body: some View {
        ContentView()
            .overlay(ChattyLauncher(botId: "YOUR_BOT_ID"))
    }
}
```

**Embedded full-screen chat** — place it directly in your own navigation, e.g. as a "Support" tab:

```swift
import ChattySDK

struct SupportScreen: View {
    var body: some View {
        ChattyChatView(botId: "YOUR_BOT_ID")
    }
}
```

## Design gallery

The SDK ships all 10 Chatty widget designs as SwiftUI color/radius tokens, ported 1:1 from the
web widget's `globals.css`, so a native screen looks like whatever design is chosen in the
dashboard rather than one generic look. No configuration required — the SDK fetches the bot's
theme and resolves the matching token set automatically, including legacy `widget_style` IDs
from older presets.

| Design | Accent |
|---|---|
| `minimal` | ![#1c1a15](https://img.shields.io/badge/%20-1c1a15?style=flat-square&color=1c1a15) |
| `playful` | ![#ff8a5c](https://img.shields.io/badge/%20-ff8a5c?style=flat-square&color=ff8a5c) |
| `corporate` | ![#1c2e4a](https://img.shields.io/badge/%20-1c2e4a?style=flat-square&color=1c2e4a) |
| `dark-sleek` | ![#00e5c7](https://img.shields.io/badge/%20-00e5c7?style=flat-square&color=00e5c7) |
| `gradient-glow` | ![#a855f7](https://img.shields.io/badge/%20-a855f7?style=flat-square&color=a855f7) |
| `glassmorphism` | ![#8f6ff0](https://img.shields.io/badge/%20-8f6ff0?style=flat-square&color=8f6ff0) |
| `ecommerce` | ![#0f9d8c](https://img.shields.io/badge/%20-0f9d8c?style=flat-square&color=0f9d8c) |
| `healthcare-calm` | ![#6f9c7d](https://img.shields.io/badge/%20-6f9c7d?style=flat-square&color=6f9c7d) |
| `neubrutalism` | ![#ff3d67](https://img.shields.io/badge/%20-ff3d67?style=flat-square&color=ff3d67) |
| `luxury-editorial` | ![#161412](https://img.shields.io/badge/%20-161412?style=flat-square&color=161412) |

Font pairing (each web design uses a distinct Google Font) is intentionally out of scope for
this release; color, radius, and header/bubble treatment carry most of a design's identity.

## API reference

### `ChattyLauncher`

```swift
public init(
    botId: String,
    baseURL: String = chattyDefaultBaseURL,
    host: String? = nil,
    position: ChattyPosition = .bottomTrailing,
    color: Color? = nil,
    onVoiceCallPress: (() -> Void)? = nil,
    onNotificationBellPress: (() -> Void)? = nil
)
```

| Param | Description |
|---|---|
| `botId` | **Required.** Your bot's ID from the dashboard. |
| `baseURL` | Chatty backend base URL. Defaults to the production API. |
| `host` | Advisory only — sent to the backend but not used for access control. See [Notes](#notes). |
| `position` | `.bottomLeading` or `.bottomTrailing`. Default `.bottomTrailing`. |
| `color` | Overrides the launcher color. Defaults to the active design's accent color. |
| `onVoiceCallPress` | Forwarded to `ChattyChatView`'s header voice-call button. See [Notes](#notes). |
| `onNotificationBellPress` | Forwarded to `ChattyChatView`'s header notification bell. See [Notes](#notes). |

### `ChattyChatView`

```swift
public init(
    botId: String,
    baseURL: String = chattyDefaultBaseURL,
    host: String? = nil,
    onMessage: ((ChattyMessage) -> Void)? = nil,
    onVoiceCallPress: (() -> Void)? = nil,
    onNotificationBellPress: (() -> Void)? = nil,
    onClose: (() -> Void)? = nil
)
```

| Param | Description |
|---|---|
| `botId` | **Required.** Your bot's ID from the dashboard. |
| `baseURL` | Chatty backend base URL. Defaults to the production API. |
| `host` | Advisory only — sent to the backend but not used for access control. See [Notes](#notes). |
| `onMessage` | Called for every inbound message — useful for unread badges or analytics. |
| `onVoiceCallPress` | Header voice-call button tapped. Only shown when the bot's dashboard has voice enabled. See [Notes](#notes). |
| `onNotificationBellPress` | Header notification-bell button tapped, after the OS permission prompt resolves. See [Notes](#notes). |
| `onClose` | Renders a close (✕) button in the header when set. `ChattyLauncher` passes this for you. |

### Notes

<details open>
<summary><strong>Security — <code>bot_id</code> and domain restriction</strong></summary>

<br>

`bot_id` is not a secret — it's extractable from any client, web or mobile. Domain restriction
(`allowed_domains` in the dashboard) is enforced by the backend as a **rate-limit tier**, not a
hard reject: verified web traffic gets 30 msgs/60s per bot+IP, everything else (including all
mobile SDK traffic — there's no way for a native app to obtain a "verified" token the way a
browser's `Referer` allows) gets throttled to 5 msgs/120s. The `host` param this SDK sends is
advisory only and isn't used for access control. If your bot is mobile-primary, leave
`allowed_domains` empty to get the normal 30/60s tier instead.

</details>

<details>
<summary><strong>Notification bell — what it does and doesn't do</strong></summary>

<br>

Tapping it requests the OS notification permission and then calls `onNotificationBellPress`.
That's as far as this SDK goes — actually *delivering* a push when a reply arrives while the app
is backgrounded needs APNs (or a wrapper like OneSignal) wired up at the app level: register the
device token, send it to your backend, store it against the session/user, and have the backend
call APNs when a message lands for a session that isn't actively polling. None of that exists
yet — it's backend work in `chatty-backend`.

</details>

<details>
<summary><strong>Voice-call button</strong></summary>

<br>

Only shown when the bot's dashboard has voice enabled, and only fires `onVoiceCallPress` — this
SDK doesn't bundle a voice-call implementation (a separate LiveKit integration, out of scope
here).

</details>

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

---

<div align="center">

**[Contributing](CONTRIBUTING.md)** — bug reports, design-parity fixes, and PRs are welcome.

Licensed under [MIT](LICENSE) © PersonaliAI

</div>
