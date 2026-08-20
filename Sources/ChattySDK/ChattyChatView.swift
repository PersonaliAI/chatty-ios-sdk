import SwiftUI
import PhotosUI
#if os(iOS)
import AVFoundation
import UIKit
#endif

/// Full Chatty chat screen: header (with voice/notification/clear-chat actions),
/// message list, conversation starters, typing indicator, and composer (emoji
/// picker, attach menu, mic recording). Equivalent to the web widget's embed
/// iframe content — sizing/spacing/structure below is ported 1:1 from
/// EmbedClient.tsx + globals.css + widget.js.
///
/// Mic recording and camera capture are iOS-only (guarded via `#if os(iOS)`
/// throughout) since this package also builds for macOS, where
/// AVAudioSession/UIImagePickerController don't exist — those two composer
/// buttons simply don't appear when built for macOS.
public struct ChattyChatView: View {
    @StateObject private var viewModel: ChattyViewModel
    @State private var input: String = ""

    /// Called when the header's voice-call button is tapped (only shown when the bot's
    /// dashboard has voice enabled). This SDK doesn't bundle a voice-call implementation
    /// itself (that's a separate LiveKit integration) — wire this up if your app has one.
    public var onVoiceCallPress: (() -> Void)?
    /// Called when the header's notification-bell button is tapped. Native apps manage
    /// push notifications through their own infrastructure (FCM/APNs), so this SDK
    /// doesn't subscribe to anything itself — wire this up to your app's own opt-in flow.
    public var onNotificationBellPress: (() -> Void)?

    public init(
        botId: String,
        baseURL: String = chattyDefaultBaseURL,
        host: String? = nil,
        onMessage: ((ChattyMessage) -> Void)? = nil,
        onVoiceCallPress: (() -> Void)? = nil,
        onNotificationBellPress: (() -> Void)? = nil
    ) {
        let vm = ChattyViewModel(botId: botId, baseURL: baseURL, host: host)
        vm.onMessage = onMessage
        _viewModel = StateObject(wrappedValue: vm)
        self.onVoiceCallPress = onVoiceCallPress
        self.onNotificationBellPress = onNotificationBellPress
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
        // px-4 pt-3 pb-2 on web -> 16pt horizontal, 12pt top, 8pt bottom.
        let content = HStack(spacing: 10) {
            // 44pt avatar circle (web: size-11), logo image at 34pt if set, else an icon at 24pt.
            let logoBg = chattyLogoBgColor(viewModel.theme?.widget_style) ?? t.headerText.opacity(0.08)
            ZStack {
                Circle().fill(logoBg).frame(width: 44, height: 44)
                if let urlStr = viewModel.theme?.logo_url, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { $0.resizable() } placeholder: { Color.clear }
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                } else {
                    Image(systemName: chattyAvatarSymbol(viewModel.theme?.avatar_icon))
                        .font(.system(size: 18))
                        .foregroundColor(t.headerText)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.theme?.name ?? "Chatty Assistant")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.headerText)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    ChattyPulsingDot(color: Color(red: 0.133, green: 0.773, blue: 0.369))
                    Text("Online · replies instantly")
                        .font(.system(size: 9))
                        .foregroundColor(t.headerText.opacity(0.7))
                }
            }
            Spacer()
            if viewModel.theme?.voice_enabled == true {
                headerActionButton(systemName: "phone.fill", tint: t.headerText) { onVoiceCallPress?() }
            }
            headerActionButton(systemName: "bell.fill", tint: t.headerText) { onNotificationBellPress?() }
            headerActionButton(systemName: "arrow.counterclockwise", tint: t.headerText) { viewModel.clearChat() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

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

    private func headerActionButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundColor(tint)
                .frame(width: 28, height: 28)
        }
    }

    private func messageList(t: ChattyDesignTokens, accent: Color) -> some View {
        GeometryReader { outerGeo in
            // max-w-[88%] on web — computed once for the list, not per row,
            // so each bubble can still size to its own content up to this cap.
            let rowMaxWidth = (outerGeo.size.width - 32) * 0.88
            ScrollViewReader { proxy in
                ScrollView {
                    // p-4 space-y-4 on web -> 16pt padding, 16pt gap between rows.
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.messages) { msg in
                            bubble(msg, t: t, maxWidth: rowMaxWidth).id(msg.id)
                        }
                        if viewModel.sending {
                            typingBubble(t: t, maxWidth: rowMaxWidth)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
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

    @ViewBuilder
    private func botAvatar(t: ChattyDesignTokens) -> some View {
        ZStack {
            Circle().fill(t.botBubbleBg).frame(width: 24, height: 24)
            if viewModel.theme?.avatar_icon == "custom", let urlStr = viewModel.theme?.avatar_url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { $0.resizable() } placeholder: { Color.clear }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            } else {
                Image(systemName: chattyAvatarSymbol(viewModel.theme?.avatar_icon))
                    .font(.system(size: 11))
                    .foregroundColor(t.botBubbleText)
            }
        }
    }

    private func bubble(_ message: ChattyMessage, t: ChattyDesignTokens, maxWidth: CGFloat) -> some View {
        let isUser = message.role == .user
        let radius = isUser ? t.userBubbleRadius : t.botBubbleRadius
        return HStack(spacing: 0) {
            if isUser { Spacer(minLength: 0) }
            HStack(alignment: .bottom, spacing: 8) {
                if !isUser { botAvatar(t: t) }
                VStack(alignment: .leading, spacing: 6) {
                    if let fileURL = message.fileURL {
                        AsyncImage(url: fileURL) { $0.resizable().aspectRatio(contentMode: .fill) } placeholder: { Color.gray.opacity(0.2) }
                            .frame(width: 180, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if !message.text.isEmpty {
                        if isUser {
                            Text(message.text)
                                .font(.system(size: 12))
                                .foregroundColor(t.userBubbleText)
                        } else {
                            parsedMessage(message.text)
                                .font(.system(size: 12))
                                .foregroundColor(t.botBubbleText)
                                .tint(t.userBubbleBg)
                        }
                    }
                }
                .padding(10) // p-2.5 on web
                .background(isUser ? t.userBubbleBg : t.botBubbleBg)
                .clipShape(ChattyBubbleShape(radius: radius, isUser: isUser))
            }
            .frame(maxWidth: maxWidth) // max-w-[88%] on web — bubble still sizes to its own content up to this cap.
            if !isUser { Spacer(minLength: 0) }
        }
    }

    private func typingBubble(t: ChattyDesignTokens, maxWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                botAvatar(t: t)
                ChattyTypingDots(color: t.botBubbleText)
                    .padding(10)
                    .background(t.botBubbleBg)
                    .clipShape(ChattyBubbleShape(radius: t.botBubbleRadius, isUser: false))
            }
            .frame(maxWidth: maxWidth)
            Spacer(minLength: 0)
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
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.userBubbleBg.opacity(0.35)))
                        }
                        .foregroundColor(t.userBubbleBg)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func banner(_ text: String, bg: Color) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(Color(red: 0.216, green: 0.255, blue: 0.318))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(bg)
    }

    @State private var showEmojiPicker = false
    @State private var showAttachMenu = false
    #if os(iOS)
    @State private var showCameraPicker = false
    @State private var isRecording = false
    @State private var recordingSeconds = 0
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingTimer: Timer?
    #endif

    private func composer(t: ChattyDesignTokens, accent: Color) -> some View {
        // Bordered rounded-16pt bar with the input on top and an icon row
        // (emoji + attach + mic + send) below, matching .chat-input-bar on web.
        VStack(alignment: .leading, spacing: 4) {
            if showEmojiPicker {
                emojiPicker
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
            if showAttachMenu {
                attachMenu(t: t)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            #if os(iOS)
            if isRecording {
                recordingIndicator
            } else {
                inputField
            }
            #else
            inputField
            #endif

            HStack(spacing: 2) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showEmojiPicker.toggle(); showAttachMenu = false
                    }
                }) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                        .frame(width: 28, height: 28)
                }
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAttachMenu.toggle(); showEmojiPicker = false
                    }
                }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                        .frame(width: 28, height: 28)
                }
                #if os(iOS)
                Button(action: { isRecording ? stopRecordingAndTranscribe() : requestMicAndRecord() }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic")
                        .foregroundColor(isRecording ? Color(red: 0.937, green: 0.267, blue: 0.267) : Color(red: 0.61, green: 0.64, blue: 0.69))
                        .frame(width: 28, height: 28)
                }
                #endif
                Spacer()
                ChattySendButton(
                    style: viewModel.theme?.send_button_style,
                    accent: accent,
                    textColor: t.userBubbleText,
                    enabled: !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.sending,
                    action: send
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(t.containerBg)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.headerText.opacity(0.12)))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(10)
        .alert("Not Supported", isPresented: $showPhotoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Photo picker requires iOS 16+.")
        }
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.9) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    try? data.write(to: tempURL)
                    viewModel.sendImage(fileURL: tempURL, mimeType: "image/jpeg", caption: "")
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private var inputField: some View {
        // The multiline `axis:`/ranged `lineLimit` TextField APIs need
        // iOS 16 — this package's deployment target is iOS 15, so fall
        // back to a single-line field there.
        if #available(iOS 16.0, *) {
            TextField("Type a message…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 12))
        } else {
            TextField("Type a message…", text: $input)
                .font(.system(size: 12))
        }
    }

    private var emojiPicker: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 8)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(ChattyEmojis.all, id: \.self) { emoji in
                Text(emoji)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .onTapGesture { input += emoji }
            }
        }
        .frame(height: 160)
    }

    private func attachMenu(t: ChattyDesignTokens) -> some View {
        HStack(spacing: 12) {
            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                attachMenuOption(systemName: "camera.fill", label: "Camera") {
                    showAttachMenu = false
                    showCameraPicker = true
                }
            }
            #endif
            if #available(iOS 16.0, macOS 13.0, *) {
                PhotoLibraryOption(onPicked: { url in
                    showAttachMenu = false
                    viewModel.sendImage(fileURL: url, mimeType: "image/jpeg", caption: "")
                })
            } else {
                attachMenuOption(systemName: "photo.fill", label: "Photo Library") {
                    showAttachMenu = false
                    showPhotoAlert = true
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func attachMenuOption(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(red: 0.953, green: 0.957, blue: 0.965))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @State private var showPhotoAlert = false

    #if os(iOS)
    private var recordingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                ChattyPulsingDot(color: Color(red: 0.937, green: 0.267, blue: 0.267), size: 8)
                Text(String(format: "Recording… %d:%02d", recordingSeconds / 60, recordingSeconds % 60))
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
            }
            Spacer()
            Button("Stop", action: stopRecordingAndTranscribe)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.vertical, 6)
    }

    private func requestMicAndRecord() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted { self.startRecording() }
            }
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record()
            audioRecorder = recorder
            recordingURL = url
            recordingSeconds = 0
            isRecording = true
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                recordingSeconds += 1
            }
        } catch {
            // mic busy/unavailable — silently no-op rather than crash the composer
        }
    }

    private func stopRecordingAndTranscribe() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        audioRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        guard let url = recordingURL, recordingSeconds >= 1 else {
            audioRecorder = nil
            recordingURL = nil
            return
        }
        audioRecorder = nil
        recordingURL = nil
        viewModel.transcribeVoiceNote(fileURL: url, mimeType: "audio/mp4") { text in
            if let text, !text.isEmpty {
                input = input.isEmpty ? text : "\(input) \(text)"
            }
        }
    }
    #endif

    private func send() {
        let text = input
        input = ""
        showEmojiPicker = false
        showAttachMenu = false
        viewModel.sendText(text)
    }
}

/// bot/logo(no logoUrl)/custom(no avatarUrl) fall back to a generic chat
/// glyph; the rest map 1:1 to the dashboard's avatar_icon options.
func chattyAvatarSymbol(_ avatarIcon: String?) -> String {
    switch avatarIcon {
    case "headset": return "headphones"
    case "sparkles": return "sparkles"
    case "message": return "message.fill"
    case "user": return "person.fill"
    default: return "bubble.left.fill"
    }
}

enum ChattyEmojis {
    static let all = [
        "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🙂", "🙃", "😉", "😊", "😇",
        "🥰", "😍", "🤩", "😘", "😋", "😛", "🤪", "😜", "🤔", "🤨", "😐", "😑",
        "😶", "🙄", "😏", "😒", "😬", "🙁", "😢", "😭", "😤", "😡", "🥳", "😴",
        "🤗", "🤝", "👍", "👎", "👏", "🙌", "🙏", "💪", "👋", "✌️", "🤞", "❤️",
        "🔥", "✨", "🎉", "🎊", "⭐", "💯", "✅", "❌", "❓", "❗", "💬", "👀",
    ]
}

private struct ChattyPulsingDot: View {
    let color: Color
    var size: CGFloat = 6
    @State private var dim = false

    var body: some View {
        Circle()
            .fill(color.opacity(dim ? 0.5 : 1))
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
    }
}

private struct ChattyTypingDots: View {
    let color: Color
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .offset(y: bounce ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                        value: bounce
                    )
            }
        }
        .onAppear { bounce = true }
    }
}

private struct ChattySendButton: View {
    let style: String?
    let accent: Color
    let textColor: Color
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        switch style {
        case "square":
            Button(action: action) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(textColor)
                    .frame(width: 32, height: 32)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }.disabled(!enabled)
        case "label":
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill").font(.system(size: 12))
                    Text("Send").font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(accent)
                .clipShape(Capsule())
            }.disabled(!enabled)
        case "arrowUp":
            roundButton(systemName: "arrow.up")
        case "arrowRight":
            roundButton(systemName: "arrow.right")
        default: // "plane"
            roundButton(systemName: "paperplane.fill")
        }
    }

    private func roundButton(systemName: String) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(accent)
                .clipShape(Circle())
        }.disabled(!enabled)
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct PhotoLibraryOption: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    let onPicked: (URL) -> Void

    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
            VStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
                Text("Photo Library")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(red: 0.953, green: 0.957, blue: 0.965))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    do {
                        try data.write(to: tempURL)
                        await MainActor.run { onPicked(tempURL) }
                    } catch {
                        print("Failed to save image")
                    }
                }
            }
        }
    }
}

#if os(iOS)
/// Wraps UIImagePickerController(.camera) — PhotosPicker/PHPicker can only
/// pick existing library assets, not drive a live camera capture.
private struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
