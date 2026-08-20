# Contributing to ChattySDK (iOS)

Thanks for considering a contribution — patches, bug reports, and design-parity
fixes against the [web widget](https://github.com/PersonaliAI/chatty) are all
welcome.

## Development setup

```bash
git clone https://github.com/Damayantha/chatty-ios-sdk.git
cd chatty-ios-sdk
open Package.swift   # opens in Xcode via Swift Package Manager
```

No external dependencies beyond Apple's own frameworks (SwiftUI, PhotosUI,
Foundation) — `swift build` should work with just an Xcode toolchain
installed, no bootstrap script needed.

```bash
swift build
swift test   # if/when a test target exists — see "Testing" below
```

The `Example/` app is the fastest way to see a change end to end: open
`Example/ChattySDKExample.xcodeproj`, run on a simulator, and it renders the
SDK exactly the way a real consuming app would.

## Project structure

```
Sources/ChattySDK/
  ChattyAPI.swift            HTTP client for /api/widget/*
  ChattySession.swift        Persistent session id (UserDefaults-backed)
  ChattyViewModel.swift      Conversation state, polling, streaming
  ChattyDesignTokens.swift   The 10 widget designs' colors/radii
  ChattyChatView.swift       Full chat screen (SwiftUI)
  ChattyLauncher.swift       Floating button + sheet-presented chat
```

## Keeping design parity with the web widget

`ChattyDesignTokens.swift` is a hand-ported mirror of
[`globals.css`](https://github.com/PersonaliAI/chatty/blob/main/frontend/src/app/globals.css)'s
`.style-*` rules. If a design's colors change on web, the same values need
updating here — there's no shared source of truth across languages (yet).
Cross-check against the web repo before opening a PR that touches these
values.

## Testing

There's no compiled-and-verified test suite in this repo yet (see the open
issue tracking this) — changes are currently reviewed by hand and against the
`Example/` app. If you're adding a non-trivial change, a `swift-testing` or
`XCTest` case covering it is very welcome.

## Pull requests

- Keep PRs scoped to one change — a design fix and a new feature should be
  two PRs, not one.
- Explain *why*, not just *what*, in the description — especially for
  anything touching design tokens or the API client's request shape.
- CI (see `.github/workflows/ci.yml`) must pass before merge.

## Reporting bugs

Open an issue with: the SDK version, iOS version, a minimal repro (ideally as
a diff against `Example/`), and what you expected vs. what happened.
