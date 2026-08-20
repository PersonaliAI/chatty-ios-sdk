import SwiftUI

public enum ChattyPosition {
    case bottomLeading, bottomTrailing
}

/// Floating launcher button + full-screen sheet chat panel — the native-SDK
/// equivalent of widget.js's launcher button + iframe panel. Add as an overlay
/// on your root view: `.overlay(ChattyLauncher(botId: "..."))`. 60pt (widget.js:
/// 60x60px), button color/shadow follow the selected design's own
/// LAUNCHER_STYLES entry unless `color` is explicitly passed, which always wins.
public struct ChattyLauncher: View {
    let botId: String
    let baseURL: String
    let host: String?
    let position: ChattyPosition
    let colorOverride: Color?
    let onVoiceCallPress: (() -> Void)?
    let onNotificationBellPress: (() -> Void)?

    @State private var open = false
    @State private var unread = 0
    @State private var designId = "minimal"
    @State private var rawWidgetStyle: String?

    public init(
        botId: String,
        baseURL: String = chattyDefaultBaseURL,
        host: String? = nil,
        position: ChattyPosition = .bottomTrailing,
        color: Color? = nil,
        onVoiceCallPress: (() -> Void)? = nil,
        onNotificationBellPress: (() -> Void)? = nil
    ) {
        self.botId = botId
        self.baseURL = baseURL
        self.host = host
        self.position = position
        self.colorOverride = color
        self.onVoiceCallPress = onVoiceCallPress
        self.onNotificationBellPress = onNotificationBellPress
    }

    private var tokens: ChattyDesignTokens { chattyDesignTokens[designId] ?? chattyDesignTokens["minimal"]! }
    private var resolvedColor: Color { colorOverride ?? tokens.launcherBg }
    private var isGradient: Bool { colorOverride == nil && designId == "gradient-glow" }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                if position == .bottomTrailing { Spacer() }
                ZStack(alignment: .topTrailing) {
                    let shape = ChattyLauncherShape(raw: rawWidgetStyle, position: position)
                    Button(action: { open = true; unread = 0 }) {
                        Text("💬")
                            .font(.system(size: 24))
                            .frame(width: 60, height: 60)
                            .background(isGradient ? AnyView(gradientBackground) : AnyView(resolvedColor))
                            .clipShape(shape)
                            .shadow(color: tokens.launcherShadow, radius: 10, y: 4)
                    }
                    if unread > 0 {
                        Text(unread > 9 ? "9+" : "\(unread)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Color(red: 0.937, green: 0.267, blue: 0.267))
                            .clipShape(Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
                if position == .bottomLeading { Spacer() }
            }
            .padding(20)
        }
        .sheet(isPresented: $open) {
            ChattyChatView(
                botId: botId,
                baseURL: baseURL,
                host: host,
                onMessage: { _ in if !open { unread += 1 } },
                onVoiceCallPress: onVoiceCallPress,
                onNotificationBellPress: onNotificationBellPress,
                onClose: { open = false }
            )
        }
        .task { await loadDesign() }
    }

    private var gradientBackground: some View {
        LinearGradient(
            colors: chattyGradientGlowHeaderColors.map { Color(hex: $0) },
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private func loadDesign() async {
        do {
            let theme = try await ChattyClient(botId: botId, baseURL: baseURL, host: host).getTheme()
            designId = chattyNormalizeWidgetStyle(theme.widget_style)
            rawWidgetStyle = theme.widget_style
        } catch {
            // keep the fallback design — a failed theme fetch shouldn't block the button from rendering
        }
    }
}
