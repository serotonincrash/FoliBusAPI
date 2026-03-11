import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public protocol FoliTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct URLSessionTransport: FoliTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
