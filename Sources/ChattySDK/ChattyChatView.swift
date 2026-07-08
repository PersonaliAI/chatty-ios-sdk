import SwiftUI

private let fallbackColor = Color(red: 0.976, green: 0.451, blue: 0.086) // #f97316

private func parseColor(_ hex: String?) -> Color {
    guard let hex, hex.hasPrefix("#"), hex.count == 7 else { return fallbackColor }
    let scanner = Scanner(string: String(hex.dropFirst()))
    var rgb: UInt64 = 0
    guard scanner.scanHexInt64(&rgb) else { return fallbackColor }
    return Color(
        red: Double((rgb >> 16) & 0xFF) / 255,
        green: Double((rgb >> 8) & 0xFF) / 255,
        blue: Double(rgb & 0xFF) / 255
    )
}

/// Full Chatty chat screen: header, message list, conversation starters, typing
/// indicator, and composer. Equivalent to the web widget's embed iframe content.
public struct ChattyChatView: View {
    @StateObject private var viewModel: ChattyViewModel
    @State private var input: String = ""

    public init(
        botId: String,
        baseURL: String = chattyDefaultBaseURL,
        host: String? = nil,
        onMessage: ((ChattyMessage) -> Void)? = nil
    ) {
        let vm = ChattyViewModel(botId: botId, baseURL: baseURL, host: host)
        vm.onMessage = onMessage
        _viewModel = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        let color = parseColor(viewModel.theme?.primary_color)

        VStack(spacing: 0) {
            if !viewModel.ready {
                Spacer()
                ProgressView().tint(color)
                Spacer()
            } else {
                header(color: color)
                messageList(color: color)
                starters(color: color)
                if viewModel.aiPaused {
                    banner("A human agent has taken over this conversation.", bg: Color(red: 0.996, green: 0.953, blue: 0.78))
                }
                if let error = viewModel.error {
                    banner(error, bg: Color(red: 0.996, green: 0.886, blue: 0.886))
                }
                composer(color: color)
            }
        }
        .onAppear { viewModel.load() }
    }

    private func header(color: Color) -> some View {
        HStack(spacing: 8) {
            if let urlStr = viewModel.theme?.logo_url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { $0.resizable() } placeholder: { Color.white.opacity(0.3) }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }
            Text(viewModel.theme?.name ?? "Chat")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(color)
    }

    private func messageList(color: Color) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.messages) { msg in
                        bubble(msg, color: color).id(msg.id)
                    }
                    if viewModel.sending {
                        typingBubble(color: color)
                    }
                }
                .padding(12)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private func bubble(_ message: ChattyMessage, color: Color) -> some View {
        let isUser = message.role == .user
        return HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                if let fileURL = message.fileURL {
                    AsyncImage(url: fileURL) { $0.resizable().aspectRatio(contentMode: .fill) } placeholder: { Color.gray.opacity(0.2) }
                        .frame(width: 180, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 14))
                        .foregroundColor(isUser ? .white : Color(red: 0.067, green: 0.094, blue: 0.153))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isUser ? color : Color(red: 0.953, green: 0.957, blue: 0.965))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            if !isUser { Spacer(minLength: 40) }
        }
    }

    private func typingBubble(color: Color) -> some View {
        HStack {
            ProgressView().tint(color).scaleEffect(0.7)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(red: 0.953, green: 0.957, blue: 0.965))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
    }

    @ViewBuilder
    private func starters(color: Color) -> some View {
        if let list = viewModel.theme?.conversation_starters, !list.isEmpty, viewModel.messages.count <= 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(list, id: \.self) { starter in
                        Button(action: { viewModel.sendText(starter) }) {
                            Text(starter)
                                .font(.system(size: 12.5))
                                .lineLimit(2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.9, green: 0.91, blue: 0.92)))
                        }
                        .foregroundColor(Color(red: 0.216, green: 0.255, blue: 0.318))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private func banner(_ text: String, bg: Color) -> some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundColor(Color(red: 0.216, green: 0.255, blue: 0.318))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(bg)
    }

    private func composer(color: Color) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Type a message…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(red: 0.976, green: 0.98, blue: 0.984))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(Circle())
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.sending)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(red: 0.9, green: 0.91, blue: 0.92)), alignment: .top)
    }

    private func send() {
        let text = input
        input = ""
        viewModel.sendText(text)
    }
}
