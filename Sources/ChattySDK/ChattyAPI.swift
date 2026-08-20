import Foundation

public let chattyDefaultBaseURL = "https://api.chatty.personaliai.com"

public struct ChattyTheme: Decodable {
    public let name: String?
    public let primary_color: String?
    public let widget_style: String?
    public let logo_url: String?
    public let welcome_message: String?
    public let send_button_style: String?
    public let conversation_starters: [String]?
    public let teaser_message: String?
    public let avatar_icon: String?
    public let avatar_url: String?
}

public struct ChattyChatResponse: Decodable {
    public let reply: String
    public let session_id: String
    public let ai_paused: Bool?
    public let file_url: String?
    public let file_type: String?
}

public struct ChattyPollMessage: Decodable {
    public let content: String
    public let created_at: String
    public let sender: String
}

public struct ChattyPollResponse: Decodable {
    public let messages: [ChattyPollMessage]
    public let ai_paused: Bool?
}

public enum ChattyError: Error, LocalizedError {
    case rateLimited
    case domainNotAllowed
    case http(Int)
    case decoding(Error)

    public var errorDescription: String? {
        switch self {
        case .rateLimited: return "Chatty: rate limit exceeded (30 messages / 60s per bot+IP)"
        case .domainNotAllowed: return "Chatty: this app/host is not in the bot's allowed_domains list"
        case .http(let code): return "Chatty request failed: \(code)"
        case .decoding(let err): return "Chatty decoding error: \(err.localizedDescription)"
        }
    }
}

/// Thin HTTP client for the Chatty widget API (`/api/widget/*`). No auth header —
/// bot_id alone identifies the bot, optionally restricted by allowed_domains via `host`.
public final class ChattyClient {
    private let botId: String
    private let baseURL: String
    private let host: String?
    private let session: URLSession

    public init(botId: String, baseURL: String = chattyDefaultBaseURL, host: String? = nil, session: URLSession = .shared) {
        self.botId = botId
        self.baseURL = baseURL
        self.host = host
        self.session = session
    }

    public func getTheme() async throws -> ChattyTheme {
        var components = URLComponents(string: "\(baseURL)/api/widget/theme")!
        components.queryItems = [
            URLQueryItem(name: "bot_id", value: botId),
            URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970 * 1000))),
        ]
        let (data, response) = try await session.data(from: components.url!)
        try Self.checkStatus(response)
        return try Self.decode(data)
    }

    public func sendMessage(sessionId: String, text: String, visitorTimezone: String = "UTC") async throws -> ChattyChatResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/widget/chat")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "bot_id": botId,
            "session_id": sessionId,
            "text": text,
            "visitor_timezone": visitorTimezone,
        ]
        if let host { body["host"] = host }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Self.checkStatus(response)
        return try Self.decode(data)
    }

    public func sendMessageStream(sessionId: String, text: String, visitorTimezone: String = "UTC") async throws -> AsyncThrowingStream<String, Error> {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/widget/chat/stream")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "bot_id": botId,
            "session_id": sessionId,
            "text": text,
            "visitor_timezone": visitorTimezone,
        ]
        if let host { body["host"] = host }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await session.bytes(for: request)
        try Self.checkStatus(response)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            guard let data = jsonString.data(using: .utf8) else { continue }
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                if let done = json["done"] as? Bool, done {
                                    continuation.finish()
                                    return
                                } else if let token = json["token"] as? String {
                                    continuation.yield(token)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func sendMedia(sessionId: String, fileURL: URL, mimeType: String, text: String = "", visitorTimezone: String = "UTC") async throws -> ChattyChatResponse {
        let boundary = "ChattyBoundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "\(baseURL)/api/widget/chat/media")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        appendField("bot_id", botId)
        appendField("session_id", sessionId)
        appendField("text", text)
        appendField("visitor_timezone", visitorTimezone)
        if let host { appendField("host", host) }

        let fileData = try Data(contentsOf: fileURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try Self.checkStatus(response)
        return try Self.decode(data)
    }

    public func poll(sessionId: String, after: String) async throws -> ChattyPollResponse {
        var components = URLComponents(string: "\(baseURL)/api/widget/poll")!
        components.queryItems = [
            URLQueryItem(name: "bot_id", value: botId),
            URLQueryItem(name: "session_id", value: sessionId),
            URLQueryItem(name: "after", value: after),
        ]
        let (data, response) = try await session.data(from: components.url!)
        try Self.checkStatus(response)
        return try Self.decode(data)
    }

    private static func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 429 { throw ChattyError.rateLimited }
        if http.statusCode == 403 { throw ChattyError.domainNotAllowed }
        if !(200...299).contains(http.statusCode) { throw ChattyError.http(http.statusCode) }
    }

    private static func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ChattyError.decoding(error)
        }
    }
}
