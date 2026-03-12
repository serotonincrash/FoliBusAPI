import Foundation

/// A minimal transport interface used by ``FoliClient`` to execute network requests.
///
/// This abstraction keeps request execution separate from request construction,
/// response validation, and decoding. Production code typically uses
/// ``URLSessionTransport``, while tests can inject a custom transport that returns
/// deterministic fixture data.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public protocol FoliTransport: Sendable {
    /// Executes the given request and returns the raw response payload and metadata.
    /// - Parameter request: The fully constructed request to execute.
    /// - Returns: The response body data and its associated URL response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// A ``FoliTransport`` implementation backed by `URLSession`.
///
/// Use this transport in production to route ``FoliClient`` requests through a
/// concrete session configuration.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct URLSessionTransport: FoliTransport {
    private let session: URLSession

    /// Creates a transport backed by the provided session.
    /// - Parameter session: The session used to execute requests. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Executes a request using the configured `URLSession`.
    /// - Parameter request: The request to execute.
    /// - Returns: The response body data and its associated URL response.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
