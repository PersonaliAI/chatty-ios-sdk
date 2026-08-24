import Foundation

/// Intercepts every request made through a `URLSession` configured with this protocol
/// class, so tests never touch the real network. Set `requestHandler` before making a
/// call and reset it in `tearDown` to avoid leaking state (and closures capturing `self`
/// or `XCTestExpectation`s) between tests.
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    /// Builds a session that routes all traffic through `MockURLProtocol`.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// Convenience for handlers that just need to return a status code + JSON body.
    static func jsonResponse(status: Int, json: [String: Any], url: URL) -> (HTTPURLResponse, Data?) {
        let data = try! JSONSerialization.data(withJSONObject: json)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        return (response, data)
    }
}
