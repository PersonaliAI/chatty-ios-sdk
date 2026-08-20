import SwiftUI

public enum ChattyPosition {
    case bottomLeading, bottomTrailing
}

/// Floating launcher button + full-screen sheet chat panel — the native-SDK
/// equivalent of widget.js's launcher button + iframe panel. Add as an overlay
/// on your root view: `.overlay(ChattyLauncher(botId: "..."))`. The button
/// color follows the selected design's own accent (same as web's
/// LAUNCHER_STYLES) unless `color` is explicitly passed, which always wins.
public struct ChattyLauncher: View {
    let botId: String
    let baseURL: String
    let host: String?
    let position: ChattyPosition
    let colorOverride: Color?

    @State private var open = false
    @State private var unread = 0
    @State private var designAccent = Color(red: 0.976, green: 0.451, blue: 0.086)

    public init(
        botId: String,
        baseURL: String = chattyDefaultBaseURL,
        host: String? = nil,
        position: ChattyPosition = .bottomTrailing,
        color: Color? = nil
    ) {
        self.botId = botId
        self.baseURL = baseURL
        self.host = host
        self.position = position
        self.colorOverride = color
    }

    private var resolvedColor: Color { colorOverride ?? designAccent }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                if position == .bottomTrailing { Spacer() }
                ZStack(alignment: .topTrailing) {
                    Button(action: { open = true; unread = 0 }) {
                        Text("💬")
                            .font(.system(size: 24))
                            .frame(width: 58, height: 58)
                            .background(resolvedColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                    }
                    if unread > 0 {
                        Text(unread > 9 ? "9+" : "\(unread)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
                if position == .bottomLeading { Spacer() }
            }
            .padding(20)
        }
        .sheet(isPresented: $open) {
            ChattyChatView(botId: botId, baseURL: baseURL, host: host) { _ in
                if !open { unread += 1 }
            }
        }
        .task { await loadDesignAccent() }
    }

    private func loadDesignAccent() async {
        guard colorOverride == nil else { return } // explicit override always wins, no need to fetch
        do {
            let theme = try await ChattyClient(botId: botId, baseURL: baseURL, host: host).getTheme()
            let designId = chattyNormalizeWidgetStyle(theme.widget_style)
            designAccent = (chattyDesignTokens[designId] ?? chattyDesignTokens["minimal"]!).userBubbleBg
        } catch {
            // keep the fallback accent — a failed theme fetch shouldn't block the button from rendering
        }
    }
}
