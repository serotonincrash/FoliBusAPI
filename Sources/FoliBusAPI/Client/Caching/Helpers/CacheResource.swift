import Foundation

public extension Foli {
    /// Identifies a cacheable (or deduplication-keyed) GTFS resource.
    ///
    /// This type serves a dual purpose:
    /// - As keys for cache operations (load, save, clear).
    /// - As deduplication keys in ``FoliClient`` to coalesce concurrent in-flight requests.
    ///
    /// The ``stopMonitoring(_:)`` case is deduplication-only and has no corresponding
    /// cache storage; it is intentionally excluded from cache protocol implementations.
    enum CacheResource: Hashable, Sendable {
        /// Real-time stop monitoring for a given stop ID (deduplication only, not cached).
        case stopMonitoring(String)
        /// Real-time vehicle monitoring (deduplication only, not cached).
        case vehicleMonitoring
        case routes
        case stops
        case trips
        case tripsForRoute(String)
        case stopTimes
        case stopTimesForTrip(String)
        case stopTimesForStop(String)
        case calendarDates
        case agencies
        case calendars
        case shapeRouteIds
        case shapePointsForShape(String)
    }
}
