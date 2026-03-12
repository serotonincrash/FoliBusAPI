import Foundation

public extension Foli {
    /// A cache interface for storing and retrieving GTFS-backed resources.
    ///
    /// The package ships with ``Foli/DiskCache`` as its default implementation,
    /// but custom caches can conform to this protocol to provide alternate storage
    /// or invalidation behavior.
    ///
    /// All methods are asynchronous to support actor-isolated implementations and
    /// avoid blocking the caller.
    protocol Cache: Sendable {
        /// Load cached routes if available and not expired
        func loadRoutes() async throws -> [Foli.Route]?

        /// Save routes to cache with current timestamp
        func saveRoutes(_ routes: [Foli.Route]) async throws

        /// Load cached stops if available and not expired
        func loadStops() async throws -> [Foli.Stop]?

        /// Save stops to cache with current timestamp
        func saveStops(_ stops: [Foli.Stop]) async throws

        /// Load cached trips if available and not expired
        func loadTrips() async throws -> [Foli.Trip]?

        /// Save trips to cache with current timestamp
        func saveTrips(_ trips: [Foli.Trip]) async throws

        /// Load cached trips for a specific route
        func loadTrips(forRoute routeId: String) async throws -> [Foli.Trip]?

        /// Save trips for a specific route
        func saveTrips(_ trips: [Foli.Trip], forRoute routeId: String) async throws

        /// Load cached stop times if available and not expired
        func loadStopTimes() async throws -> [Foli.StopTime]?

        /// Save stop times to cache with current timestamp
        func saveStopTimes(_ stopTimes: [Foli.StopTime]) async throws

        /// Load cached stop times for a specific trip
        func loadStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]?

        /// Save stop times for a specific trip
        func saveStopTimes(_ stopTimes: [Foli.StopTime], forTrip tripId: String) async throws

        /// Load cached stop times for a specific stop
        func loadStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]?

        /// Save stop times for a specific stop
        func saveStopTimes(_ stopTimes: [Foli.StopTime], forStop stopId: String) async throws

        /// Load cached calendar dates if available and not expired
        func loadCalendarDates() async throws -> [Foli.CalendarDate]?

        /// Save calendar dates to cache with current timestamp
        func saveCalendarDates(_ calendarDates: [Foli.CalendarDate]) async throws

        /// Clear all cached data
        func clearAllCache() async throws

        /// Clear cached data for a specific type
        func clearCache(for type: Foli.CacheResource) async throws

        /// Check if cached data exists and is valid (not expired)
        func hasValidCache(for type: Foli.CacheResource) async -> Bool

        /// Get the age of cached data in seconds, or nil if not cached
        func cacheAge(for type: Foli.CacheResource) async -> TimeInterval?

        /// Get the dataset ID being used for cached data
        /// - Parameter type: The specific resource type to check, or nil to get the most recently cached dataset ID
        /// - Returns: The dataset ID, or nil if no cached data exists
        func currentDatasetId(for type: Foli.CacheResource?) async throws -> String?

        /// The configuration for this cache
        var timeoutDuration: Foli.CacheTimeout { get }

        /// The most recently cached dataset ID across all resources
        var currentDatasetId: String? { get async throws }

        /// Load cached routes regardless of freshness.
        func loadStaleRoutes() async throws -> [Foli.Route]?

        /// Load cached stops regardless of freshness.
        func loadStaleStops() async throws -> [Foli.Stop]?

        /// Load cached trips regardless of freshness.
        func loadStaleTrips() async throws -> [Foli.Trip]?

        /// Load cached trips for a specific route regardless of freshness.
        func loadStaleTrips(forRoute routeId: String) async throws -> [Foli.Trip]?

        /// Load cached stop times regardless of freshness.
        func loadStaleStopTimes() async throws -> [Foli.StopTime]?

        /// Load cached stop times for a specific trip regardless of freshness.
        func loadStaleStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]?

        /// Load cached stop times for a specific stop regardless of freshness.
        func loadStaleStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]?

        /// Load cached calendar dates regardless of freshness.
        func loadStaleCalendarDates() async throws -> [Foli.CalendarDate]?

        /// Revalidate cached data for a resource, returning true if the cache remained current.
        @discardableResult
        func revalidateCache(for type: Foli.CacheResource) async throws -> Bool
    }
}
