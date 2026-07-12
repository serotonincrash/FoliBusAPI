import Foundation

public extension Foli {
    /// Identifies an in-flight request for deduplication purposes.
    ///
    /// Distinct from ``Resource`` (the cache key), which is dataset-scoped and persists
    /// across app launches. A `DedupeKey` is request-scoped: it exists only to coalesce
    /// concurrent identical requests and is cleared when the request completes.
    enum DedupeKey: Hashable, Sendable {
        /// A cacheable resource — the dedupe key wraps the cache resource key.
        case resource(Foli.Resource)
        /// Real-time stop monitoring for a given stop ID.
        case stopMonitoring(String)
        /// Real-time vehicle monitoring.
        case vehicleMonitoring
        /// Real-time alerts.
        case alerts
        /// Real-time alert messages only.
        case alertMessages
        /// Real-time cancellations only.
        case alertCancellations
    }
}
