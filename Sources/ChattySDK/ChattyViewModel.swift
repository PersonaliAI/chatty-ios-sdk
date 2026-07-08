import Foundation

public enum ChattyRole {
    case user, assistant, agent
}

public struct ChattyMessage: Identifiable {
    public let id: String
    public let role: ChattyRole
    public let text: String
    public let createdAt: String
    public let fileURL: URL?

    public init(id: String = UUID().uuidString, role: ChattyRole, text: String, createdAt: String = ISO8601DateFormatter().string(from: Date()), fileURL: URL? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.fileURL = fileURL
    }
}

/// Drives a full Chatty conversation: loads bot theme/config, manages the
/// persistent session id, sends messages, and polls for human-agent replies
/// every 4s — the native-SDK equivalent of widget.js's embed iframe lifecycle.
@MainActor
public final class ChattyViewModel: ObservableObject {
    @Published public private(set) var theme: ChattyTheme?
    @Published public private(set) var ready: Bool = false
    @Published public private(set) var messages: [ChattyMessage] = []
    @Published public private(set) var sending: Bool = false
    @Published public private(set) var aiPaused: Bool = false
    @Published public private(set) var error: String?

    private let client: ChattyClient
    private let botId: String
    private let hostKey: String
    private let pollIntervalSeconds: Double
    private let visitorTimezone: String
    public var onMessage: ((ChattyMessage) -> Void)?

    private var sessionId: String?
    private var lastPollAt: String = ISO8601DateFormatter().string(from: Date())
    private var pollTask: Task<Void, Never>?

    public init(
        botId: String,
        baseURL: String = chattyDefaultBaseURL,
        host: String? = nil,
        hostKey: String = "app",
        pollIntervalSeconds: Double = 4.0,
        visitorTimezone: String = "UTC"
    ) {
        self.botId = botId
        self.client = ChattyClient(botId: botId, baseURL: baseURL, host: host)
        self.hostKey = hostKey
        self.pollIntervalSeconds = pollIntervalSeconds
        self.visitorTimezone = visitorTimezone
    }

    public func load() {
        guard !ready else { return }
        Task {
            do {
                let theme = try await client.getTheme()
                self.theme = theme
                self.sessionId = ChattySession.getOrCreateSessionId(botId: botId, hostKey: hostKey)
                if let welcome = theme.welcome_message, !welcome.isEmpty {
                    self.messages = [ChattyMessage(id: "welcome", role: .assistant, text: welcome)]
                }
                self.ready = true
                startPolling()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    deinit {
        pollTask?.cancel()
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pollIntervalSeconds * 1_000_000_000))
                guard !Task.isCancelled, let sid = self.sessionId else { continue }
                do {
                    let res = try await self.client.poll(sessionId: sid, after: self.lastPollAt)
                    if let last = res.messages.last {
                        self.lastPollAt = last.created_at
                        let newMessages = res.messages.map {
                            ChattyMessage(role: $0.sender == "agent" ? .agent : .assistant, text: $0.content, createdAt: $0.created_at)
                        }
                        self.messages.append(contentsOf: newMessages)
                        newMessages.forEach { self.onMessage?($0) }
                    }
                    self.aiPaused = res.ai_paused ?? false
                } catch {
                    // silent — polling failures shouldn't surface as user-facing errors
                }
            }
        }
    }

    public func sendText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let sid = sessionId else { return }
        messages.append(ChattyMessage(role: .user, text: trimmed))
        sending = true
        error = nil
        Task {
            do {
                let res = try await client.sendMessage(sessionId: sid, text: trimmed, visitorTimezone: visitorTimezone)
                self.aiPaused = res.ai_paused ?? false
                if !(res.ai_paused ?? false), !res.reply.isEmpty {
                    let reply = ChattyMessage(role: .assistant, text: res.reply)
                    self.messages.append(reply)
                    self.onMessage?(reply)
                }
            } catch {
                self.error = error.localizedDescription
            }
            self.sending = false
        }
    }

    public func sendImage(fileURL: URL, mimeType: String, caption: String = "") {
        guard let sid = sessionId else { return }
        messages.append(ChattyMessage(role: .user, text: caption, fileURL: fileURL))
        sending = true
        error = nil
        Task {
            do {
                let res = try await client.sendMedia(sessionId: sid, fileURL: fileURL, mimeType: mimeType, text: caption, visitorTimezone: visitorTimezone)
                self.aiPaused = res.ai_paused ?? false
                if !(res.ai_paused ?? false), !res.reply.isEmpty {
                    let reply = ChattyMessage(role: .assistant, text: res.reply)
                    self.messages.append(reply)
                    self.onMessage?(reply)
                }
            } catch {
                self.error = error.localizedDescription
            }
            self.sending = false
        }
    }
}
