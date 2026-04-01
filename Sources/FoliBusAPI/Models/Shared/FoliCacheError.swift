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
        case resourceNotCacheable(Resource)
        
        public var errorDescription: String? {
            switch self {
            case .resourceNotCacheable(let resource):
                return "Resource '\(resource)' is not cacheable. Real-time data types use deduplication only and cannot be persisted to disk."
            }
        }
    }
}
