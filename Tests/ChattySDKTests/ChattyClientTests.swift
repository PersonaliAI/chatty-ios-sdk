import XCTest
@testable import ChattySDK

final class ChattyClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeClient(botId: String = "bot-123", baseURL: String = "https://example.test", host: String? = nil) -> ChattyClient {
        ChattyClient(botId: botId, baseURL: baseURL, host: host, session: MockURLProtocol.makeSession())
    }

    // MARK: - getTheme

    func testGetThemeSuccessDecodesAllFields() async throws {
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            return MockURLProtocol.jsonResponse(status: 200, json: [
                "name": "Acme Bot",
                "primary_color": "#ff0000",
                "widget_style": "minimal:#fff:bubble",
                "logo_url": "https://example.test/logo.png",
                "welcome_message": "Hi there",
                "send_button_style": "arrow",
                "conversation_starters": ["Hello", "Pricing?"],
                "teaser_message": "Need help?",
                "avatar_icon": "robot",
                "avatar_url": NSNull(),
                "voice_enabled": true,
            ], url: url)
        }

        let client = makeClient()
        let theme = try await client.getTheme()

        XCTAssertEqual(theme.name, "Acme Bot")
        XCTAssertEqual(theme.primary_color, "#ff0000")
        XCTAssertEqual(theme.widget_style, "minimal:#fff:bubble")
        XCTAssertEqual(theme.welcome_message, "Hi there")
        XCTAssertEqual(theme.conversation_starters, ["Hello", "Pricing?"])
        XCTAssertEqual(theme.voice_enabled, true)
        XCTAssertNil(theme.avatar_url)
    }

    func testGetThemeToleratesAllFieldsMissing() async throws {
        // Every field on ChattyTheme is Optional, so an empty object must still decode.
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 200, json: [:], url: request.url!)
        }

        let theme = try await makeClient().getTheme()
        XCTAssertNil(theme.name)
        XCTAssertNil(theme.welcome_message)
        XCTAssertNil(theme.voice_enabled)
    }

    func testGetThemeBuildsExpectedURLAndQueryItems() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return MockURLProtocol.jsonResponse(status: 200, json: [:], url: request.url!)
        }

        _ = try await makeClient(botId: "bot-abc", baseURL: "https://example.test").getTheme()

        let url = try XCTUnwrap(capturedRequest?.url)
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "example.test")
        XCTAssertEqual(url.path, "/api/widget/theme")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryNames = Set(components.queryItems?.map { $0.name } ?? [])
        XCTAssertTrue(queryNames.contains("bot_id"))
        XCTAssertTrue(queryNames.contains("t"))
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "bot_id" })?.value, "bot-abc")
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
    }

    // MARK: - sendMessage

    func testSendMessageSuccessDecodesResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 200, json: [
                "reply": "Hello, how can I help?",
                "session_id": "sess-1",
                "ai_paused": false,
                "file_url": NSNull(),
                "file_type": NSNull(),
            ], url: request.url!)
        }

        let response = try await makeClient().sendMessage(sessionId: "sess-1", text: "hi")
        XCTAssertEqual(response.reply, "Hello, how can I help?")
        XCTAssertEqual(response.session_id, "sess-1")
        XCTAssertEqual(response.ai_paused, false)
        XCTAssertNil(response.file_url)
    }

    func testSendMessageRequestShapeAndBody() async throws {
        var capturedRequest: URLRequest?
        var capturedBodyJSON: [String: Any]?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            if let bodyData = request.httpBodyStreamData() ?? request.httpBody {
                capturedBodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            }
            return MockURLProtocol.jsonResponse(status: 200, json: [
                "reply": "ok", "session_id": "sess-1",
            ], url: request.url!)
        }

        _ = try await makeClient(host: "widget.example.com").sendMessage(
            sessionId: "sess-1", text: "hello world", visitorTimezone: "Asia/Colombo"
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/widget/chat")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(capturedBodyJSON)
        XCTAssertEqual(body["bot_id"] as? String, "bot-123")
        XCTAssertEqual(body["session_id"] as? String, "sess-1")
        XCTAssertEqual(body["text"] as? String, "hello world")
        XCTAssertEqual(body["visitor_timezone"] as? String, "Asia/Colombo")
        XCTAssertEqual(body["host"] as? String, "widget.example.com")
    }

    func testSendMessageOmitsHostWhenNil() async throws {
        var capturedBodyJSON: [String: Any]?
        MockURLProtocol.requestHandler = { request in
            if let bodyData = request.httpBodyStreamData() ?? request.httpBody {
                capturedBodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            }
            return MockURLProtocol.jsonResponse(status: 200, json: ["reply": "ok", "session_id": "sess-1"], url: request.url!)
        }

        _ = try await makeClient(host: nil).sendMessage(sessionId: "sess-1", text: "hi")

        let body = try XCTUnwrap(capturedBodyJSON)
        XCTAssertNil(body["host"])
    }

    // MARK: - error handling

    func testRateLimitedThrowsChattyErrorRateLimited() async {
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 429, json: ["error": "too many requests"], url: request.url!)
        }

        do {
            _ = try await makeClient().getTheme()
            XCTFail("expected ChattyError.rateLimited to be thrown")
        } catch let error as ChattyError {
            guard case .rateLimited = error else {
                return XCTFail("expected .rateLimited, got \(error)")
            }
        } catch {
            XCTFail("expected ChattyError, got \(error)")
        }
    }

    func testForbiddenThrowsChattyErrorDomainNotAllowed() async {
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 403, json: [:], url: request.url!)
        }

        do {
            _ = try await makeClient().getTheme()
            XCTFail("expected ChattyError.domainNotAllowed to be thrown")
        } catch let error as ChattyError {
            guard case .domainNotAllowed = error else {
                return XCTFail("expected .domainNotAllowed, got \(error)")
            }
        } catch {
            XCTFail("expected ChattyError, got \(error)")
        }
    }

    func testServerErrorThrowsChattyErrorHTTPWithCode() async {
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 500, json: [:], url: request.url!)
        }

        do {
            _ = try await makeClient().getTheme()
            XCTFail("expected ChattyError.http(500) to be thrown")
        } catch let error as ChattyError {
            guard case .http(let code) = error else {
                return XCTFail("expected .http, got \(error)")
            }
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("expected ChattyError, got \(error)")
        }
    }

    func testMalformedJSONThrowsChattyErrorDecoding() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, "not valid json".data(using: .utf8))
        }

        do {
            _ = try await makeClient().sendMessage(sessionId: "s", text: "hi")
            XCTFail("expected ChattyError.decoding to be thrown")
        } catch let error as ChattyError {
            guard case .decoding = error else {
                return XCTFail("expected .decoding, got \(error)")
            }
        } catch {
            XCTFail("expected ChattyError, got \(error)")
        }
    }

    func testMissingRequiredFieldThrowsChattyErrorDecoding() async {
        // ChattyChatResponse.reply and .session_id are non-optional; omitting them must fail decode.
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 200, json: ["ai_paused": false], url: request.url!)
        }

        do {
            _ = try await makeClient().sendMessage(sessionId: "s", text: "hi")
            XCTFail("expected ChattyError.decoding to be thrown")
        } catch let error as ChattyError {
            guard case .decoding = error else {
                return XCTFail("expected .decoding, got \(error)")
            }
        } catch {
            XCTFail("expected ChattyError, got \(error)")
        }
    }

    func testNetworkFailurePropagatesUnderlyingError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await makeClient().getTheme()
            XCTFail("expected an error to be thrown")
        } catch let urlError as URLError {
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        } catch {
            XCTFail("expected URLError, got \(error)")
        }
    }

    // MARK: - poll

    func testPollBuildsExpectedQueryItemsAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return MockURLProtocol.jsonResponse(status: 200, json: [
                "messages": [
                    ["content": "hi from agent", "created_at": "2026-08-24T00:00:00Z", "sender": "agent"],
                ],
                "ai_paused": true,
            ], url: request.url!)
        }

        let result = try await makeClient().poll(sessionId: "sess-9", after: "2026-08-23T00:00:00Z")

        let components = URLComponents(url: try XCTUnwrap(capturedRequest?.url), resolvingAgainstBaseURL: false)!
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items["bot_id"], "bot-123")
        XCTAssertEqual(items["session_id"], "sess-9")
        XCTAssertEqual(items["after"], "2026-08-23T00:00:00Z")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/widget/poll")

        XCTAssertEqual(result.messages.count, 1)
        XCTAssertEqual(result.messages.first?.sender, "agent")
        XCTAssertEqual(result.ai_paused, true)
    }

    // MARK: - sendMedia / transcribe (multipart)

    func testSendMediaSendsMultipartBodyWithFieldsAndFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("chatty-test-\(UUID().uuidString).txt")
        try "file-bytes".data(using: .utf8)!.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var capturedRequest: URLRequest?
        var capturedBody: Data?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            capturedBody = request.httpBodyStreamData() ?? request.httpBody
            return MockURLProtocol.jsonResponse(status: 200, json: ["reply": "got it", "session_id": "sess-1"], url: request.url!)
        }

        _ = try await makeClient(host: "app.example.com").sendMedia(
            sessionId: "sess-1", fileURL: tempURL, mimeType: "text/plain", text: "a caption"
        )

        let contentType = try XCTUnwrap(capturedRequest?.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary=ChattyBoundary-"))

        let bodyString = String(data: try XCTUnwrap(capturedBody), encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("name=\"bot_id\""))
        XCTAssertTrue(bodyString.contains("bot-123"))
        XCTAssertTrue(bodyString.contains("name=\"session_id\""))
        XCTAssertTrue(bodyString.contains("name=\"text\""))
        XCTAssertTrue(bodyString.contains("a caption"))
        XCTAssertTrue(bodyString.contains("name=\"host\""))
        XCTAssertTrue(bodyString.contains("app.example.com"))
        XCTAssertTrue(bodyString.contains("filename=\"\(tempURL.lastPathComponent)\""))
        XCTAssertTrue(bodyString.contains("file-bytes"))
    }

    func testTranscribeReturnsDecodedText() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("chatty-audio-\(UUID().uuidString).wav")
        try Data([0x00, 0x01, 0x02]).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.jsonResponse(status: 200, json: ["text": "transcribed words"], url: request.url!)
        }

        let text = try await makeClient().transcribe(fileURL: tempURL, mimeType: "audio/wav")
        XCTAssertEqual(text, "transcribed words")
    }
}

private extension URLRequest {
    /// `URLProtocol` may surface the body via `httpBodyStream` instead of `httpBody`
    /// depending on how the request was constructed; normalize to `Data` for assertions.
    func httpBodyStreamData() -> Data? {
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }
}
