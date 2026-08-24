import XCTest
@testable import ChattySDK

final class ChattyMessageTests: XCTestCase {
    func testInitAssignsProvidedValues() {
        let fileURL = URL(string: "https://example.test/file.png")!
        let message = ChattyMessage(id: "abc", role: .user, text: "hello", createdAt: "2026-08-24T00:00:00Z", fileURL: fileURL)

        XCTAssertEqual(message.id, "abc")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.text, "hello")
        XCTAssertEqual(message.createdAt, "2026-08-24T00:00:00Z")
        XCTAssertEqual(message.fileURL, fileURL)
    }

    func testInitGeneratesDefaultsWhenOmitted() {
        let message = ChattyMessage(role: .assistant, text: "hi")
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertNil(message.fileURL)
        XCTAssertFalse(message.createdAt.isEmpty)
    }

    func testTwoDefaultInitsProduceDifferentIds() {
        let a = ChattyMessage(role: .assistant, text: "hi")
        let b = ChattyMessage(role: .assistant, text: "hi")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testRoleRawValuesMatchBackendVocabulary() {
        XCTAssertEqual(ChattyRole.user.rawValue, "user")
        XCTAssertEqual(ChattyRole.assistant.rawValue, "assistant")
        XCTAssertEqual(ChattyRole.agent.rawValue, "agent")
    }

    func testCodableRoundTripPreservesAllFields() throws {
        let original = ChattyMessage(
            id: "msg-1", role: .agent, text: "human reply",
            createdAt: "2026-08-24T01:02:03Z", fileURL: URL(string: "https://example.test/a.jpg")
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChattyMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.createdAt, original.createdAt)
        XCTAssertEqual(decoded.fileURL, original.fileURL)
    }

    func testCodableRoundTripWithNilFileURL() throws {
        let original = ChattyMessage(id: "msg-2", role: .user, text: "no attachment", createdAt: "2026-08-24T01:02:03Z", fileURL: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChattyMessage.self, from: data)
        XCTAssertNil(decoded.fileURL)
    }

    func testArrayCodableRoundTripMatchesViewModelPersistenceUsage() throws {
        // ChattyViewModel persists [ChattyMessage] as a single JSON blob in UserDefaults;
        // exercise that same shape here.
        let messages = [
            ChattyMessage(role: .assistant, text: "welcome"),
            ChattyMessage(role: .user, text: "hi"),
            ChattyMessage(role: .agent, text: "how can I help"),
        ]
        let data = try JSONEncoder().encode(messages)
        let decoded = try JSONDecoder().decode([ChattyMessage].self, from: data)
        XCTAssertEqual(decoded.map(\.text), messages.map(\.text))
        XCTAssertEqual(decoded.map(\.role), messages.map(\.role))
    }

    func testDecodingUnknownRoleFails() {
        let json = """
        {"id":"1","role":"bot","text":"hi","createdAt":"2026-08-24T00:00:00Z","fileURL":null}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ChattyMessage.self, from: json))
    }
}
