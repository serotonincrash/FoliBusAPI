import Foundation

// MARK: - Cache Errors
public extension Foli {
    /// Errors that can occur during cache operations.
    ///
    /// These errors represent misuse of the caching layer or cache-specific failures,
    /// distinct from API-level errors which occur during network requests.
    enum CacheError: Error, LocalizedError, Sendable {
        /// No cached value is available for the requested resource.
        ///
        /// Thrown when cache behavior is `.cachedOnly` and the cache does not contain
        /// a usable entry for the resource. Distinct from `Foli.APIError` cases, which
        /// represent network/transport/decoding failures.
        case cacheMiss(Resource)

        public var errorDescription: String? {
            switch self {
            case .cacheMiss(let resource):
                return "No cached value available for '\(resource)'."
            }
        }
    }
}
