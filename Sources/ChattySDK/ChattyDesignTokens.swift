import SwiftUI

/// The 10 widget designs' key visual tokens, ported 1:1 from the web
/// widget's globals.css (`.style-*` rules) so the native chat view matches
/// whatever design the bot owner picked in the dashboard instead of always
/// rendering a single generic orange-on-white look. Font pairing (each
/// design uses a distinct Google Font on web) is intentionally out of scope
/// here — bundling 6 font families into this SDK is a separate, larger
/// piece of work; colors, radii, and header/bubble treatment are the part
/// that carries most of a design's visual identity.
public struct ChattyDesignTokens {
    public let containerBg: Color
    public let headerBg: Color
    public let headerText: Color
    public let botBubbleBg: Color
    public let botBubbleText: Color
    public let botBubbleRadius: CGFloat
    public let userBubbleBg: Color
    public let userBubbleText: Color
    public let userBubbleRadius: CGFloat

    public init(containerBg: String, headerBg: String, headerText: String,
                botBubbleBg: String, botBubbleText: String, botBubbleRadius: CGFloat,
                userBubbleBg: String, userBubbleText: String, userBubbleRadius: CGFloat) {
        self.containerBg = Color(hex: containerBg)
        self.headerBg = Color(hex: headerBg)
        self.headerText = Color(hex: headerText)
        self.botBubbleBg = Color(hex: botBubbleBg)
        self.botBubbleText = Color(hex: botBubbleText)
        self.botBubbleRadius = botBubbleRadius
        self.userBubbleBg = Color(hex: userBubbleBg)
        self.userBubbleText = Color(hex: userBubbleText)
        self.userBubbleRadius = userBubbleRadius
    }
}

// gradient-glow's header is a linear-gradient(120deg, #a855f7, #ec4899) on
// web; SwiftUI's LinearGradient is used directly at the call site for that
// one design instead of trying to encode a gradient into a single Color.
public let chattyGradientGlowHeaderColors: [String] = ["#a855f7", "#ec4899"]

public let chattyDesignTokens: [String: ChattyDesignTokens] = [
    "minimal": ChattyDesignTokens(
        containerBg: "#f3f2ee", headerBg: "#ffffff", headerText: "#1c1a15",
        botBubbleBg: "#f3f2ee", botBubbleText: "#1c1a15", botBubbleRadius: 14,
        userBubbleBg: "#1c1a15", userBubbleText: "#ffffff", userBubbleRadius: 14),
    "playful": ChattyDesignTokens(
        containerBg: "#fffaf5", headerBg: "#ff8a5c", headerText: "#ffffff",
        botBubbleBg: "#ffe6d9", botBubbleText: "#7a3f24", botBubbleRadius: 20,
        userBubbleBg: "#ff8a5c", userBubbleText: "#ffffff", userBubbleRadius: 20),
    "corporate": ChattyDesignTokens(
        containerBg: "#eef1f6", headerBg: "#1c2e4a", headerText: "#ffffff",
        botBubbleBg: "#eef1f6", botBubbleText: "#1c2e4a", botBubbleRadius: 8,
        userBubbleBg: "#1c2e4a", userBubbleText: "#ffffff", userBubbleRadius: 8),
    "dark-sleek": ChattyDesignTokens(
        containerBg: "#111114", headerBg: "#14141a", headerText: "#e4e4e8",
        botBubbleBg: "#1c1c22", botBubbleText: "#e4e4e8", botBubbleRadius: 12,
        userBubbleBg: "#00e5c7", userBubbleText: "#05201c", userBubbleRadius: 12),
    // headerBg here is a placeholder — see chattyGradientGlowHeaderColors above.
    "gradient-glow": ChattyDesignTokens(
        containerBg: "#ffffff", headerBg: "#a855f7", headerText: "#ffffff",
        botBubbleBg: "#f6effc", botBubbleText: "#4a2467", botBubbleRadius: 16,
        userBubbleBg: "#a855f7", userBubbleText: "#ffffff", userBubbleRadius: 16),
    "glassmorphism": ChattyDesignTokens(
        containerBg: "#8f6ff0", headerBg: "#ffffff1a", headerText: "#ffffff",
        botBubbleBg: "#ffffff2e", botBubbleText: "#ffffff", botBubbleRadius: 14,
        userBubbleBg: "#ffffffe6", userBubbleText: "#39396b", userBubbleRadius: 14),
    "ecommerce": ChattyDesignTokens(
        containerBg: "#fdf9f2", headerBg: "#0f9d8c", headerText: "#ffffff",
        botBubbleBg: "#f3efe6", botBubbleText: "#3a3226", botBubbleRadius: 14,
        userBubbleBg: "#0f9d8c", userBubbleText: "#ffffff", userBubbleRadius: 14),
    "healthcare-calm": ChattyDesignTokens(
        containerBg: "#fbfcf9", headerBg: "#eaf1e9", headerText: "#2f4235",
        botBubbleBg: "#eaf1e9", botBubbleText: "#2f4235", botBubbleRadius: 14,
        userBubbleBg: "#6f9c7d", userBubbleText: "#ffffff", userBubbleRadius: 14),
    "neubrutalism": ChattyDesignTokens(
        containerBg: "#ffffff", headerBg: "#ffde59", headerText: "#111111",
        botBubbleBg: "#f2f2f2", botBubbleText: "#111111", botBubbleRadius: 4,
        userBubbleBg: "#ff3d67", userBubbleText: "#ffffff", userBubbleRadius: 4),
    "luxury-editorial": ChattyDesignTokens(
        containerBg: "#fbf9f5", headerBg: "#161412", headerText: "#f5efe3",
        botBubbleBg: "#f1ebdf", botBubbleText: "#2a251d", botBubbleRadius: 2,
        userBubbleBg: "#161412", userBubbleText: "#f5efe3", userBubbleRadius: 2),
]

/// Maps every historical widget_style ID (across all 3 preset generations
/// this project has shipped) onto one of the 10 current design keys above —
/// mirrors widget-style.ts's LEGACY_STYLE_MAP so a bot configured before the
/// current design system still renders with a matching look here instead of
/// falling through to the fallback color.
private let chattyLegacyStyleMap: [String: String] = [
    "liquid": "glassmorphism", "neumorphism": "corporate", "claymorphism": "playful",
    "bento": "minimal", "brutalism": "neubrutalism", "retro": "dark-sleek", "aurora": "gradient-glow",
    "minimalist": "minimal", "elevated": "corporate", "frosted": "glassmorphism",
    "bold": "gradient-glow", "contrast": "dark-sleek",
]

/// `widget_style` from the theme API is `"{styleId}:{logoBgColor}:{launcherShape}"`.
public func chattyNormalizeWidgetStyle(_ raw: String?) -> String {
    guard let raw, !raw.isEmpty else { return "minimal" }
    let id = raw.split(separator: ":", maxSplits: 1).first.map(String.init) ?? raw
    if chattyDesignTokens[id] != nil { return id }
    return chattyLegacyStyleMap[id] ?? "minimal"
}

extension Color {
    /// Accepts "#rrggbb" or "#rrggbbaa".
    init(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        var rgba: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgba)
        if s.count == 8 {
            self = Color(
                red: Double((rgba >> 24) & 0xFF) / 255,
                green: Double((rgba >> 16) & 0xFF) / 255,
                blue: Double((rgba >> 8) & 0xFF) / 255,
                opacity: Double(rgba & 0xFF) / 255
            )
        } else {
            self = Color(
                red: Double((rgba >> 16) & 0xFF) / 255,
                green: Double((rgba >> 8) & 0xFF) / 255,
                blue: Double(rgba & 0xFF) / 255
            )
        }
    }
}
