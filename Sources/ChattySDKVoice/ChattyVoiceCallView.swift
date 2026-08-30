// NOTE: written without the ability to run Xcode or a device/simulator in
// this environment. Every LiveKit Swift SDK type/method referenced here was
// verified by cloning the real tagged source (both 2.16.0 and 2.13.0, the
// version this package is actually pinned to — see Package.swift) and
// reading it directly: Room.connect/disconnect, Room.localParticipant, the
// RoomDelegate protocol's exact method signatures, LocalParticipant.
// setMicrophone, Participant.identity/audioLevel, TranscriptionSegment's
// fields (isFinal, not "final" as on Android/RN), ConnectionState's cases,
// AudioManager.shared.isSpeakerOutputPreferred. GitHub Actions CI (real
// Xcode, runs on every push) did catch one real error this static reading
// missed: Timer.scheduledTimer's closure capturing [weak self] then reading
// it inside a nested Task caused a Swift concurrency "captured var in
// concurrently-executing code" error — replaced with a plain Task-based
// loop, natural for an already-@MainActor class. What's still NOT verified:
// that a real call works end-to-end on device (mic permission, actual
// audio, transcript rendering). Test that before releasing.
import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#endif
import LiveKit
import ChattySDK

private enum ChattyCallStatus: Equatable {
    case connecting, requestingMic, connected, listening, agentSpeaking, error(String), ended
}

private struct ChattyTranscriptEntry: Identifiable, Equatable {
    let id: String
    let fromVisitor: Bool
    var text: String
    var isFinal: Bool
}

/// Bridges LiveKit's delegate-based Room API into SwiftUI's observable-object
/// model, same role ChattyViewModel plays for the text chat.
@MainActor
private final class ChattyVoiceCallModel: NSObject, ObservableObject, RoomDelegate {
    @Published var status: ChattyCallStatus = .connecting
    @Published var transcript: [ChattyTranscriptEntry] = []
    @Published var muted = false
    @Published var duration = 0

    private var room: Room?
    private var durationTask: Task<Void, Never>?

    func start(client: ChattyClient, sessionId: String, visitorTimezone: String) async {
        do {
            let tok = try await client.getVoiceToken(sessionId: sessionId, visitorTimezone: visitorTimezone)
            let r = Room(delegate: self)
            room = r

            #if os(iOS)
            AudioManager.shared.isSpeakerOutputPreferred = true
            #endif

            try await r.connect(url: tok.livekit_url, token: tok.token)
            status = .requestingMic
            do {
                _ = try await r.localParticipant.setMicrophone(enabled: true)
            } catch {
                status = .error("Microphone access is required for voice calls. Please allow microphone access and try again.")
                await r.disconnect()
                return
            }
            status = .connected
            startDurationCounter()
        } catch {
            status = .error((error as? LocalizedError)?.errorDescription ?? "Couldn't start the call, please try again.")
        }
    }

    func toggleMute() {
        guard let room else { return }
        let next = !muted
        muted = next
        Task { _ = try? await room.localParticipant.setMicrophone(enabled: !next) }
    }

    func hangup() async {
        durationTask?.cancel()
        if let room {
            _ = try? await room.localParticipant.setMicrophone(enabled: false)
            await room.disconnect()
        }
        room = nil
    }

    // A Task-based loop instead of Timer.scheduledTimer(_:) — this class is
    // already @MainActor, so a plain `while` loop here runs on the main
    // actor with no capture-across-concurrency-domains concerns the way a
    // Timer's own (non-actor-isolated) closure had. Cancelling the Task
    // (hangup, or deinit via the didSet below) stops the loop via
    // Task.isCancelled; Task.sleep itself throws CancellationError, which
    // the try? swallows into a clean exit.
    private func startDurationCounter() {
        durationTask?.cancel()
        durationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                self?.duration += 1
            }
        }
    }

    // MARK: - RoomDelegate (calls may arrive off the main thread — this class
    // is @MainActor, so the compiler hops back for us).

    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldConnectionState: ConnectionState) {
        if connectionState == .connected, status != .agentSpeaking { status = .connected }
    }

    func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        durationTask?.cancel()
        if case .error = status { return }
        status = .ended
    }

    func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
        let localIdentity = room.localParticipant.identity
        var remoteLevel: Float = 0
        var localSpeaking = false
        for p in participants {
            if p.identity == localIdentity { localSpeaking = true }
            else { remoteLevel = max(remoteLevel, p.audioLevel) }
        }
        switch status {
        case .connecting, .requestingMic, .error, .ended:
            return
        default:
            if remoteLevel > 0.01 { status = .agentSpeaking }
            else if localSpeaking { status = .listening }
            else { status = .connected }
        }
    }

    func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {
        let fromVisitor = participant.identity == room.localParticipant.identity
        for seg in segments {
            if let idx = transcript.firstIndex(where: { $0.id == seg.id }) {
                transcript[idx].text = seg.text
                transcript[idx].isFinal = seg.isFinal
            } else {
                transcript.append(ChattyTranscriptEntry(id: seg.id, fromVisitor: fromVisitor, text: seg.text, isFinal: seg.isFinal))
            }
        }
    }
}

/// Full-screen voice-call UI — present this when ``ChattyChatView``'s header
/// phone button is tapped and `theme.voice_enabled` is true, e.g.:
///
/// ```swift
/// @State private var showCall = false
///
/// var body: some View {
///     if showCall {
///         ChattyVoiceCallView(client: client, sessionId: sessionId,
///             widgetStyle: theme?.widget_style, onClose: { showCall = false })
///     } else {
///         ChattyChatView(botId: "YOUR_BOT_ID", onVoiceCallPress: { showCall = true })
///     }
/// }
/// ```
///
/// Add `NSMicrophoneUsageDescription` to your app's Info.plist. LiveKit's
/// Swift SDK is pulled in automatically as this target's own dependency
/// (see Package.swift for why it's pinned below 2.14.0) once you add the
/// ChattySDKVoice product — no separate dependency to add yourself.
public struct ChattyVoiceCallView: View {
    @StateObject private var model = ChattyVoiceCallModel()
    private let client: ChattyClient
    private let sessionId: String
    private let visitorTimezone: String
    private let onClose: () -> Void
    private let tokens: ChattyDesignTokens

    public init(client: ChattyClient, sessionId: String, widgetStyle: String?, visitorTimezone: String = "UTC", onClose: @escaping () -> Void) {
        self.client = client
        self.sessionId = sessionId
        self.visitorTimezone = visitorTimezone
        self.onClose = onClose
        let id = chattyNormalizeWidgetStyle(widgetStyle)
        self.tokens = chattyDesignTokens[id] ?? chattyDesignTokens["minimal"]!
    }

    public var body: some View {
        ZStack {
            tokens.containerBg.ignoresSafeArea()
            switch model.status {
            case .error(let message):
                ChattyCallEndState(systemImage: "exclamationmark.triangle.fill", iconBg: Color.red.opacity(0.12), iconTint: .red,
                                    title: message, subtitle: nil, tokens: tokens, buttonLabel: "Close", onButtonTap: onClose)
            case .ended:
                ChattyCallEndState(systemImage: "phone.down.fill", iconBg: tokens.userBubbleBg.opacity(0.12), iconTint: tokens.userBubbleBg,
                                    title: "Call ended", subtitle: fmt(model.duration), tokens: tokens, buttonLabel: "Back to chat", onButtonTap: onClose)
            default:
                activeCallBody
            }
        }
        .task {
            await model.start(client: client, sessionId: sessionId, visitorTimezone: visitorTimezone)
        }
        .onDisappear {
            Task { await model.hangup() }
        }
    }

    private var statusLabel: String {
        switch model.status {
        case .connecting: return "Connecting…"
        case .requestingMic: return "Please allow microphone access…"
        case .connected: return fmt(model.duration)
        case .listening: return "Listening…"
        case .agentSpeaking: return "Speaking…"
        default: return ""
        }
    }

    private var activeCallBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ChattyCallOrb(active: model.status == .agentSpeaking, color: tokens.userBubbleBg)
                if model.status == .connecting || model.status == .requestingMic {
                    ProgressView().scaleEffect(0.7)
                }
                Text(statusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tokens.headerText.opacity(0.7))
                Spacer()
            }
            .padding(.bottom, 12)
            .overlay(Rectangle().frame(height: 1).foregroundColor(tokens.headerText.opacity(0.06)), alignment: .bottom)

            ScrollViewReader { proxy in
                ScrollView {
                    if model.transcript.isEmpty {
                        Text("Say something — your conversation will appear here.")
                            .font(.system(size: 12))
                            .foregroundColor(tokens.headerText.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(model.transcript) { entry in
                                HStack {
                                    if entry.fromVisitor { Spacer(minLength: 40) }
                                    Text(entry.text.isEmpty ? "…" : entry.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(entry.fromVisitor ? tokens.userBubbleText : tokens.botBubbleText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(entry.fromVisitor ? tokens.userBubbleBg : tokens.botBubbleBg)
                                        .clipShape(ChattyCallBubbleShape(fromVisitor: entry.fromVisitor))
                                        .id(entry.id)
                                    if !entry.fromVisitor { Spacer(minLength: 40) }
                                }
                            }
                        }
                    }
                }
                .onChange(of: model.transcript.count) { _ in
                    if let last = model.transcript.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            .padding(.vertical, 12)

            HStack(spacing: 20) {
                Button(action: { model.toggleMute() }) {
                    Image(systemName: model.muted ? "mic.slash.fill" : "mic.fill")
                        .foregroundColor(tokens.headerText)
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(tokens.headerText.opacity(0.2), lineWidth: 1))
                }
                .disabled(model.status == .connecting || model.status == .requestingMic)

                Button(action: { onClose() }) {
                    Image(systemName: "phone.down.fill")
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 12)
        }
        .padding(16)
    }

    private func fmt(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ChattyCallBubbleShape: Shape {
    let fromVisitor: Bool
    func path(in rect: CGRect) -> Path {
        let radii = fromVisitor
            ? RectCorners(topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4)
            : RectCorners(topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16)
        return roundedPath(rect: rect, corners: radii)
    }
}

private struct RectCorners {
    let topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat
}

private func roundedPath(rect: CGRect, corners: RectCorners) -> Path {
    var path = Path()
    let tl = corners.topLeft, tr = corners.topRight, bl = corners.bottomLeft, br = corners.bottomRight
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

private struct ChattyCallOrb: View {
    let active: Bool
    let color: Color
    @State private var scale: CGFloat = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 36, height: 36)
            .overlay(Circle().fill(Color.white.opacity(0.3)).frame(width: 20, height: 20))
            .scaleEffect(scale)
            .onAppear { animate() }
            .onChange(of: active) { _ in animate() }
    }

    private func animate() {
        withAnimation(.easeInOut(duration: active ? 0.32 : 0.9).repeatForever(autoreverses: true)) {
            scale = active ? 1.15 : 1.04
        }
    }
}

private struct ChattyCallEndState: View {
    let systemImage: String
    let iconBg: Color
    let iconTint: Color
    let title: String
    let subtitle: String?
    let tokens: ChattyDesignTokens
    let buttonLabel: String
    let onButtonTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Circle().fill(iconBg).frame(width: 56, height: 56)
                .overlay(Image(systemName: systemImage).foregroundColor(iconTint).font(.system(size: 22)))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tokens.headerText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let subtitle {
                Text(subtitle).font(.system(size: 12)).foregroundColor(tokens.headerText.opacity(0.6))
            }
            Button(action: onButtonTap) {
                Text(buttonLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(tokens.userBubbleText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(tokens.userBubbleBg)
                    .clipShape(Capsule())
            }
        }
    }
}
