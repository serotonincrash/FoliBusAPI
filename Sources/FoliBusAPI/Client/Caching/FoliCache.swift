import Foundation

extension Foli {
    /// Internal cache interface for storing and retrieving GTFS-backed resources.
    ///
    /// The package currently ships with an internal disk-backed implementation and does not
    /// expose cache injection as part of the public API surface.
    ///
    /// All methods are asynchronous to support actor-isolated implementations and
    /// avoid blocking the caller.
    protocol Cache: Sendable {
        // MARK: - Generic Resource Access (conformors implement these)

        /// Load a cached resource if available and not expired.
        func loadResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T?

        /// Load a cached resource regardless of freshness.
        func loadStaleResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T?

        /// Save a resource to cache with the current timestamp.
        ///
        /// - Parameters:
        ///   - value: The value to persist.
        ///   - key: The resource key to store it under.
        ///   - datasetId: The dataset ID to tag the saved entry with, captured by the
        ///     caller *before* the network fetch that produced `value` (fail-safe
        ///     ordering: a mid-fetch dataset flip yields a stale tag, which the next
        ///     revalidation detects as a mismatch and refetches — it never gets stuck
        ///     serving stale-forever). Pass `nil` to fall back to the cache's own
        ///     `datasetIdFetcher` for revalidation-driven saves that don't have a
        ///     pre-fetch snapshot available.
        func saveResource<T: Codable & Sendable>(_ value: T, forKey key: Foli.Resource, datasetId: String?) async throws

        // MARK: - Cache Management (unchanged)

        /// Clear all cached data
        func clearAllCache() async throws

        /// Clear cached data for a specific type
        func clearCache(for type: Foli.Resource) async throws

        /// Check if cached data exists and is valid (not expired)
        func hasValidCache(for type: Foli.Resource) async -> Bool

        /// Get the age of cached data in seconds, or nil if not cached
        func cacheAge(for type: Foli.Resource) async -> TimeInterval?

        /// Get the dataset ID being used for cached data
        /// - Parameter type: The specific resource type to check, or nil to get the most recently cached dataset ID
        /// - Returns: The dataset ID, or nil if no cached data exists
        func currentDatasetId(for type: Foli.Resource?) async throws -> String?

        /// The configuration for this cache
        var timeoutDuration: Foli.CacheTTL { get }

        /// The most recently cached dataset ID across all resources
        var currentDatasetId: String? { get async throws }

        /// Revalidate cached data for a resource, returning true if the cache remained current.
        @discardableResult
        func revalidateCache(for type: Foli.Resource) async throws -> Bool

        /// Fetches the latest dataset ID over the network (via the injected
        /// `datasetIdFetcher`), for tagging a save that is about to occur.
        ///
        /// Callers should capture this *before* the corresponding network fetch so a
        /// mid-fetch dataset flip fails safe (see ``saveResource(_:forKey:datasetId:)``).
        func fetchLatestDatasetId() async throws -> String
    }
}
