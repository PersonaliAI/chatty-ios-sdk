import SwiftUI
import PhotosUI

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

    /// Falls back to primary_color-on-white when the bot uses an unrecognized
    /// widget_style (shouldn't happen — chattyNormalizeWidgetStyle always
    /// resolves to one of the 10 keys — but keeps this view crash-proof).
    private var tokens: ChattyDesignTokens {
        let id = chattyNormalizeWidgetStyle(viewModel.theme?.widget_style)
        return chattyDesignTokens[id] ?? chattyDesignTokens["minimal"]!
    }
    private var isGradientGlow: Bool {
        chattyNormalizeWidgetStyle(viewModel.theme?.widget_style) == "gradient-glow"
    }

    public var body: some View {
        let t = tokens
        // The send button and the "primary accent" (spinner tint etc.) track
        // the design's own user-bubble color, same as web — every design's
        // .send-btn background matches its .user-bubble background there.
        let accent = t.userBubbleBg

        VStack(spacing: 0) {
            if !viewModel.ready {
                Spacer()
                ProgressView().tint(accent)
                Spacer()
            } else {
                header(t: t)
                messageList(t: t, accent: accent)
                starters(t: t)
                if viewModel.aiPaused {
                    banner("A human agent has taken over this conversation.", bg: Color(red: 0.996, green: 0.953, blue: 0.78))
                }
                if let error = viewModel.error {
                    banner(error, bg: Color(red: 0.996, green: 0.886, blue: 0.886))
                }
                composer(t: t, accent: accent)
            }
        }
        .background(t.containerBg)
        .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private func header(t: ChattyDesignTokens) -> some View {
        let content = HStack(spacing: 8) {
            if let urlStr = viewModel.theme?.logo_url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { $0.resizable() } placeholder: { Color.white.opacity(0.3) }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }
            Text(viewModel.theme?.name ?? "Chat")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(t.headerText)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)

        if isGradientGlow {
            content.background(
                LinearGradient(
                    colors: chattyGradientGlowHeaderColors.map { Color(hex: $0) },
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
        } else {
            content.background(t.headerBg)
        }
    }

    private func messageList(t: ChattyDesignTokens, accent: Color) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.messages) { msg in
                        bubble(msg, t: t).id(msg.id)
                    }
                    if viewModel.sending {
                        typingBubble(t: t, accent: accent)
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

    private func parsedMessage(_ text: String) -> Text {
        if #available(iOS 15.0, *) {
            do {
                return Text(try AttributedString(markdown: text))
            } catch {
                return Text(text)
            }
        } else {
            return Text(text)
        }
    }

    private func bubble(_ message: ChattyMessage, t: ChattyDesignTokens) -> some View {
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
                    if isUser {
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(t.userBubbleText)
                    } else {
                        parsedMessage(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(t.botBubbleText)
                            .tint(t.userBubbleBg)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isUser ? t.userBubbleBg : t.botBubbleBg)
            .clipShape(RoundedRectangle(cornerRadius: isUser ? t.userBubbleRadius : t.botBubbleRadius))
            if !isUser { Spacer(minLength: 40) }
        }
    }

    private func typingBubble(t: ChattyDesignTokens, accent: Color) -> some View {
        HStack {
            ProgressView().tint(accent).scaleEffect(0.7)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(t.botBubbleBg)
                .clipShape(RoundedRectangle(cornerRadius: t.botBubbleRadius))
            Spacer()
        }
    }

    @ViewBuilder
    private func starters(t: ChattyDesignTokens) -> some View {
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
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.userBubbleBg.opacity(0.35)))
                        }
                        .foregroundColor(t.userBubbleBg)
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

    @State private var showPhotoAlert = false

    private func composer(t: ChattyDesignTokens, accent: Color) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if #available(iOS 16.0, *) {
                PhotoPickerButton(color: accent, viewModel: viewModel)
            } else {
                Button(action: { showPhotoAlert = true }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        .frame(width: 36, height: 36)
                }
                .alert(isPresented: $showPhotoAlert) {
                    Alert(title: Text("Not Supported"), message: Text("Photo picker requires iOS 16+."), dismissButton: .default(Text("OK")))
                }
            }

            TextField("Type a message…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(red: 0.976, green: 0.98, blue: 0.984))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .foregroundColor(t.userBubbleText)
                    .frame(width: 36, height: 36)
                    .background(accent)
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

@available(iOS 16.0, *)
private struct PhotoPickerButton: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    let color: Color
    let viewModel: ChattyViewModel

    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
            Image(systemName: "paperclip")
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(width: 36, height: 36)
        }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    do {
                        try data.write(to: tempURL)
                        await MainActor.run {
                            viewModel.sendImage(fileURL: tempURL, mimeType: "image/jpeg", caption: "")
                        }
                    } catch {
                        print("Failed to save image")
                    }
                }
            }
        }
    }
}
