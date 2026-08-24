import XCTest
@testable import ChattySDK

final class ChattyErrorTests: XCTestCase {
    func testRateLimitedDescriptionMentionsBothTiers() {
        let message = ChattyError.rateLimited.errorDescription ?? ""
        XCTAssertTrue(message.contains("30 msgs/60s"))
        XCTAssertTrue(message.contains("5 msgs/120s"))
    }

    func testDomainNotAllowedDescriptionMentions403() {
        XCTAssertEqual(ChattyError.domainNotAllowed.errorDescription, "Chatty: request rejected (403)")
    }

    func testHTTPDescriptionIncludesStatusCode() {
        XCTAssertEqual(ChattyError.http(500).errorDescription, "Chatty request failed: 500")
        XCTAssertEqual(ChattyError.http(404).errorDescription, "Chatty request failed: 404")
    }

    func testDecodingDescriptionWrapsUnderlyingError() {
        struct Dummy: Error, LocalizedError {
            var errorDescription: String? { "dummy failure" }
        }
        let message = ChattyError.decoding(Dummy()).errorDescription ?? ""
        XCTAssertTrue(message.contains("dummy failure"))
        XCTAssertTrue(message.hasPrefix("Chatty decoding error:"))
    }

    func testLocalizedErrorConformanceSurfacesLocalizedDescription() {
        let error: Error = ChattyError.http(503)
        XCTAssertEqual(error.localizedDescription, "Chatty request failed: 503")
    }
}
