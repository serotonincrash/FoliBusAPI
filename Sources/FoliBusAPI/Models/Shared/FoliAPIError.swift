import Foundation

// MARK: - Errors
public extension Foli {
    /// Errors that can occur while constructing requests, executing them, or decoding responses.
    enum APIError: Error, LocalizedError, Sendable {
        /// A request URL could not be constructed.
        case invalidURL
        /// The server response was missing or had an unexpected status code.
        case invalidResponse
        /// The transport layer failed before a valid response could be produced.
        case networkError(any Error)
        /// The response payload could not be decoded into the requested model.
        case decodingError(any Error)
        /// The server returned an application-level error payload.
        case serverError(String)
        /// A fetch succeeded but no entity matched the requested identifier.
        case notFound

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
            case .notFound:
                return "No entity matched the requested identifier"
            }
        }
    }
}
