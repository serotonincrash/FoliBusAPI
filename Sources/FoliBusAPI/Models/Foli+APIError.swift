import Foundation

// MARK: - Errors
public extension Foli {
    enum APIError: Error, LocalizedError, Sendable {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case decodingError(Error)
        case serverError(String)
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
