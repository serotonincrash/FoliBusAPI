import Foundation

// MARK: - Errors
public extension Foli {
    /// Errors that can occur while constructing requests, executing them, or decoding responses.
    enum APIError: Error, LocalizedError, Sendable {
        /// Wraps an underlying error in a sendable container so ``APIError`` remains safe to pass across concurrency domains.
        public struct WrappedError: Error, LocalizedError, Sendable {
            public let base: any Error
            public let description: String

            public init(_ base: any Error) {
                self.base = base
                self.description = base.localizedDescription
            }

            public var errorDescription: String? {
                description
            }
        }

        /// A request URL could not be constructed.
        case invalidURL
        /// The server response was missing or had an unexpected status code.
        case invalidResponse
        /// The transport layer failed before a valid response could be produced.
        case networkError(WrappedError)
        /// The response payload could not be decoded into the requested model.
        case decodingError(WrappedError)
        /// The server returned an application-level error payload.
        case serverError(String)
        /// A requested cached value was unavailable.
        case noData

        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .serverError(let message):
                return "Server error: \(message)"
            case .noData:
                return "No data available"
            }
        }
    }
}
