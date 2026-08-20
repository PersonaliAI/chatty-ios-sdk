import SwiftUI

/// The 10 widget designs' visual tokens, ported 1:1 from the web widget's
/// globals.css (`.style-*` rules) and widget.js's `LAUNCHER_STYLES` so the
/// native chat view matches whatever design the bot owner picked in the
/// dashboard. Font pairing (each design uses a distinct Google Font on web)
/// is intentionally out of scope here — bundling 5 font families into this
/// SDK is a separate, larger piece of work; colors, radii, and structural
/// sizing are the part that carries most of a design's visual identity.
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
    // widget.js's LAUNCHER_STYLES — NOT always the same as userBubbleBg (e.g.
    // dark-sleek's launcher is dark, not its teal accent; neubrutalism's
    // launcher is black, not its pink accent).
    public let launcherBg: Color
    public let launcherShadow: Color

    public init(containerBg: String, headerBg: String, headerText: String,
                botBubbleBg: String, botBubbleText: String, botBubbleRadius: CGFloat,
                userBubbleBg: String, userBubbleText: String, userBubbleRadius: CGFloat,
                launcherBg: String, launcherShadow: String) {
        self.containerBg = Color(hex: containerBg)
        self.headerBg = Color(hex: headerBg)
        self.headerText = Color(hex: headerText)
        self.botBubbleBg = Color(hex: botBubbleBg)
        self.botBubbleText = Color(hex: botBubbleText)
        self.botBubbleRadius = botBubbleRadius
        self.userBubbleBg = Color(hex: userBubbleBg)
        self.userBubbleText = Color(hex: userBubbleText)
        self.userBubbleRadius = userBubbleRadius
        self.launcherBg = Color(hex: launcherBg)
        self.launcherShadow = Color(hex: launcherShadow)
    }
}

// gradient-glow's header/launcher is a linear-gradient(#a855f7, #ec4899) on
// web; SwiftUI's LinearGradient is used directly at call sites for that one
// design instead of trying to encode a gradient into a single Color.
public let chattyGradientGlowHeaderColors: [String] = ["#a855f7", "#ec4899"]

public let chattyDesignTokens: [String: ChattyDesignTokens] = [
    "minimal": ChattyDesignTokens(
        containerBg: "#f3f2ee", headerBg: "#ffffff", headerText: "#1c1a15",
        botBubbleBg: "#f3f2ee", botBubbleText: "#1c1a15", botBubbleRadius: 14,
        userBubbleBg: "#1c1a15", userBubbleText: "#ffffff", userBubbleRadius: 14,
        launcherBg: "#1c1a15", launcherShadow: "#0000002E"),
    "playful": ChattyDesignTokens(
        containerBg: "#fffaf5", headerBg: "#ff8a5c", headerText: "#ffffff",
        botBubbleBg: "#ffe6d9", botBubbleText: "#7a3f24", botBubbleRadius: 20,
        userBubbleBg: "#ff8a5c", userBubbleText: "#ffffff", userBubbleRadius: 20,
        launcherBg: "#ff8a5c", launcherShadow: "#FF8A5C73"),
    "corporate": ChattyDesignTokens(
        containerBg: "#eef1f6", headerBg: "#1c2e4a", headerText: "#ffffff",
        botBubbleBg: "#eef1f6", botBubbleText: "#1c2e4a", botBubbleRadius: 8,
        userBubbleBg: "#1c2e4a", userBubbleText: "#ffffff", userBubbleRadius: 8,
        launcherBg: "#1c2e4a", launcherShadow: "#1C2E4A4C"),
    "dark-sleek": ChattyDesignTokens(
        containerBg: "#111114", headerBg: "#14141a", headerText: "#e4e4e8",
        botBubbleBg: "#1c1c22", botBubbleText: "#e4e4e8", botBubbleRadius: 12,
        userBubbleBg: "#00e5c7", userBubbleText: "#05201c", userBubbleRadius: 12,
        // Launcher is dark (matches header), not the teal accent bubble color.
        launcherBg: "#14141a", launcherShadow: "#00E5C759"),
    // headerBg/launcherBg here are placeholders — see chattyGradientGlowHeaderColors above.
    "gradient-glow": ChattyDesignTokens(
        containerBg: "#ffffff", headerBg: "#a855f7", headerText: "#ffffff",
        botBubbleBg: "#f6effc", botBubbleText: "#4a2467", botBubbleRadius: 16,
        userBubbleBg: "#a855f7", userBubbleText: "#ffffff", userBubbleRadius: 16,
        launcherBg: "#a855f7", launcherShadow: "#A855F766"),
    "glassmorphism": ChattyDesignTokens(
        containerBg: "#8f6ff0", headerBg: "#ffffff1a", headerText: "#ffffff",
        botBubbleBg: "#ffffff2e", botBubbleText: "#ffffff", botBubbleRadius: 14,
        userBubbleBg: "#ffffffe6", userBubbleText: "#39396b", userBubbleRadius: 14,
        // Launcher is translucent white (rgba(255,255,255,.25)), lighter than the near-opaque user bubble.
        launcherBg: "#ffffff40", launcherShadow: "#00000033"),
    "ecommerce": ChattyDesignTokens(
        containerBg: "#fdf9f2", headerBg: "#0f9d8c", headerText: "#ffffff",
        botBubbleBg: "#f3efe6", botBubbleText: "#3a3226", botBubbleRadius: 14,
        userBubbleBg: "#0f9d8c", userBubbleText: "#ffffff", userBubbleRadius: 14,
        launcherBg: "#0f9d8c", launcherShadow: "#0F9D8C59"),
    "healthcare-calm": ChattyDesignTokens(
        containerBg: "#fbfcf9", headerBg: "#eaf1e9", headerText: "#2f4235",
        botBubbleBg: "#eaf1e9", botBubbleText: "#2f4235", botBubbleRadius: 14,
        userBubbleBg: "#6f9c7d", userBubbleText: "#ffffff", userBubbleRadius: 14,
        launcherBg: "#6f9c7d", launcherShadow: "#6F9C7D59"),
    "neubrutalism": ChattyDesignTokens(
        containerBg: "#ffffff", headerBg: "#ffde59", headerText: "#111111",
        botBubbleBg: "#f2f2f2", botBubbleText: "#111111", botBubbleRadius: 4,
        userBubbleBg: "#ff3d67", userBubbleText: "#ffffff", userBubbleRadius: 4,
        // Launcher is black with a hard offset shadow, not the pink accent bubble color.
        launcherBg: "#111111", launcherShadow: "#111111"),
    "luxury-editorial": ChattyDesignTokens(
        containerBg: "#fbf9f5", headerBg: "#161412", headerText: "#f5efe3",
        botBubbleBg: "#f1ebdf", botBubbleText: "#2a251d", botBubbleRadius: 2,
        userBubbleBg: "#161412", userBubbleText: "#f5efe3", userBubbleRadius: 2,
        launcherBg: "#161412", launcherShadow: "#0000004D"),
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

/// The 2nd colon-segment of `widget_style`, e.g. `"minimal:#fff:bubble"` -> `"#fff"` —
/// overrides the header/bubble avatar circle's background when a real logo/avatar image
/// isn't shown.
public func chattyLogoBgColor(_ raw: String?) -> Color? {
    guard let raw else { return nil }
    let parts = raw.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
    guard parts.count >= 2, !parts[1].isEmpty else { return nil }
    return Color(hex: parts[1])
}

/// The 3rd colon-segment of `widget_style` controls the launcher button's corner shape:
/// `square` -> 0pt corners, `rounded` -> 12pt corners, `bubble` -> an asymmetric "speech
/// tail" corner, anything else (including absent) -> a full circle, matching widget.js.
public struct ChattyLauncherShape: Shape {
    let raw: String?
    let position: ChattyPosition

    public func path(in rect: CGRect) -> Path {
        let parts = raw?.split(separator: ":", omittingEmptySubsequences: false).map(String.init) ?? []
        let shapeId = parts.count >= 3 ? parts[2] : nil
        switch shapeId {
        case "square":
            return Path(rect)
        case "rounded":
            return Path(RoundedRectangle(cornerRadius: 12).path(in: rect).cgPath)
        case "bubble":
            let isTrailing = position == .bottomTrailing
            let tl: CGFloat = 30, tr: CGFloat = 30
            let br: CGFloat = isTrailing ? 30 : 4
            let bl: CGFloat = isTrailing ? 4 : 30
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
            path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
            path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()
            return path
        default:
            return Path(ellipseIn: rect)
        }
    }
}

/// Message bubble shape with the corner nearest the avatar squared off,
/// matching web's `.rounded-tl-none` (bot) / `.rounded-tr-none` (user) — the
/// "speech tail" corner treatment used by every design.
public struct ChattyBubbleShape: Shape {
    let radius: CGFloat
    let isUser: Bool

    public func path(in rect: CGRect) -> Path {
        // Plain Core Graphics (no UIKit) so this also compiles for the
        // package's macOS target.
        let tl: CGFloat = isUser ? radius : 0
        let tr: CGFloat = isUser ? 0 : radius
        let bl: CGFloat = radius
        let br: CGFloat = radius

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
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
