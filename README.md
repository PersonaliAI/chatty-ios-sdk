# ChattySDK (iOS)

Native SwiftUI chat widget SDK for Chatty — talks to the same `/api/widget/*` backend as the web widget, rendered with real SwiftUI views (no WebView).

> **Note:** this package was written in an environment without Xcode/swiftc, so it has not been compiled, built, or run on a simulator/device. Open it in Xcode and build before shipping.

## Install (Swift Package Manager)

In Xcode: File → Add Package Dependencies → point at this `ios/` directory (or a Git URL once published), then add `ChattySDK` to your app target.

## Usage — floating launcher (recommended)

```swift
import ChattySDK

struct RootView: View {
    var body: some View {
        ContentView()
            .overlay(ChattyLauncher(botId: "YOUR_BOT_ID"))
    }
}
```

## Usage — embedded full-screen chat

```swift
import ChattySDK

struct SupportScreen: View {
    var body: some View {
        ChattyChatView(botId: "YOUR_BOT_ID")
    }
}
```

## Notes

- If the bot has `allowed_domains` configured in the dashboard, pass a matching `host` value — native apps don't send an `Origin`/`Referer` header, so without a matching `host`, requests are rejected with 403. Leave `allowed_domains` empty for mobile-only bots to skip this.
- Lead capture and meeting booking happen conversationally (the assistant decides to ask/act) — there's no separate REST call to trigger them from the SDK.
- Polling for human-agent takeover messages runs every 4s while the chat view is active, matching the web widget.
- Requires iOS 15+ (uses `async`/`await`, `@StateObject`).
