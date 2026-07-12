import Foundation

// MARK: - Cache Errors
public extension Foli {
    /// Errors that can occur during cache operations.
    ///
    /// These errors represent misuse of the caching layer or cache-specific failures,
    /// distinct from API-level errors which occur during network requests.
    enum CacheError: Error, LocalizedError, Sendable {
        /// Attempted to perform a disk cache operation on a resource type that is not cacheable.
        ///
        /// Some resource types (real-time data like vehicle monitoring, stop monitoring, and alerts)
        /// are configured for deduplication only and should never be persisted to disk.
        /// This error indicates a programming error where disk cache methods were called
        /// with incompatible resource types.
        @available(*, deprecated, message: "All Foli.Resource cases are now cacheable. This case is never thrown.")
        case resourceNotCacheable(Resource)

        /// No cached value is available for the requested resource.
        ///
        /// Thrown when cache behavior is `.cachedOnly` and the cache does not contain
        /// a usable entry for the resource. Distinct from `Foli.APIError` cases, which
        /// represent network/transport/decoding failures.
        case cacheMiss(Resource)

        public var errorDescription: String? {
            switch self {
            case .resourceNotCacheable(let resource):
                return "Resource '\(resource)' is not cacheable. Real-time data types use deduplication only and cannot be persisted to disk."
            case .cacheMiss(let resource):
                return "No cached value available for '\(resource)'."
            }
        }
    }
}
