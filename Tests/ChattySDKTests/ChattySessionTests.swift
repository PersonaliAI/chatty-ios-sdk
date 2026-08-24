import XCTest
@testable import ChattySDK

final class ChattySessionTests: XCTestCase {
    // Use a unique botId per test run so we never collide with real app data
    // or with other tests sharing UserDefaults.standard.
    private var botId = ""

    override func setUp() {
        super.setUp()
        botId = "test-bot-\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "chatty_sid_\(botId)_app")
        UserDefaults.standard.removeObject(forKey: "chatty_sid_\(botId)_custom")
        super.tearDown()
    }

    func testGetOrCreateSessionIdCreatesAndPersists() {
        let first = ChattySession.getOrCreateSessionId(botId: botId)
        XCTAssertTrue(first.hasPrefix("v-"))

        let second = ChattySession.getOrCreateSessionId(botId: botId)
        XCTAssertEqual(first, second, "a second call should return the persisted id, not mint a new one")
    }

    func testGetOrCreateSessionIdIsScopedByHostKey() {
        let appSession = ChattySession.getOrCreateSessionId(botId: botId, hostKey: "app")
        let customSession = ChattySession.getOrCreateSessionId(botId: botId, hostKey: "custom")
        XCTAssertNotEqual(appSession, customSession)
    }

    func testNewSessionOverwritesExistingId() {
        let original = ChattySession.getOrCreateSessionId(botId: botId)
        let refreshed = ChattySession.newSession(botId: botId)
        XCTAssertNotEqual(original, refreshed)

        // getOrCreate should now see the refreshed id, not the original.
        let fetched = ChattySession.getOrCreateSessionId(botId: botId)
        XCTAssertEqual(fetched, refreshed)
    }

    func testSessionIdHasNoHyphensAfterPrefix() {
        // newSession strips hyphens from the UUID before appending it to "v-".
        let sid = ChattySession.newSession(botId: botId)
        let suffix = sid.dropFirst(2) // drop "v-"
        XCTAssertFalse(suffix.contains("-"))
        XCTAssertEqual(suffix, suffix.lowercased())
    }
}
