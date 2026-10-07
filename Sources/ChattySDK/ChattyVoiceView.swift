import SwiftUI
#if os(iOS)
import WebKit
#endif

/// Standalone LiveKit voice-agent UI backed by Chatty's official web embed.
/// The page renders the official LiveKit controls, visualizer, audio renderer,
/// and real-time transcript; this view does not contain or expose LiveKit
/// credentials.
 #if os(iOS)
public struct ChattyVoiceView: UIViewRepresentable {
    public let botId: String
    public let baseURL: String

    public init(botId: String, baseURL: String = "https://chatty.personaliai.com") {
        self.botId = botId
        self.baseURL = baseURL
    }

    public func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        if let url = URL(string: "\(baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/embed/\(botId)?voice=only") {
            view.load(URLRequest(url: url))
        }
        return view
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#else
/// macOS fallback: use the same hosted voice surface in a browser/web view
/// supplied by the host application. The token API remains available through
/// `ChattyClient.createVoiceToken` for a native LiveKit macOS client.
public struct ChattyVoiceView: View {
    public let botId: String
    public let baseURL: String

    public init(botId: String, baseURL: String = "https://chatty.personaliai.com") {
        self.botId = botId
        self.baseURL = baseURL
    }

    public var body: some View {
        Link("Open Chatty voice agent", destination: URL(string: "\(baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/embed/\(botId)?voice=only")!)
    }
}
#endif
