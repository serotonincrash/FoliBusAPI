import Foundation

// MARK: - Cache Resource Keys
public extension Foli {
    /// Identifies a cacheable (or deduplication-keyed) GTFS resource.
    ///
    /// This type serves a dual purpose:
    /// - As keys for cache operations (load, save, clear).
    /// - As deduplication keys in ``FoliClient`` to coalesce concurrent in-flight requests.
    ///
    /// Resources are categorized as:
    /// - **Cached**: GTFS static data that changes infrequently (routes, stops, trips, etc.)
    /// - **Deduplication-only**: Real-time data that should not be cached but benefits
    ///   from coalescing duplicate concurrent requests.
    ///
    /// ## Example
    /// ```swift
    /// // GTFS data is cached and deduplicated
    /// let routes = try await client.fetchRoutes()  // Uses .routes key
    ///
    /// // Real-time data is deduplicated but not cached
    /// let alerts = try await client.fetchAlerts()  // Uses .alerts key
    /// ```
    enum CacheResource: Hashable, Sendable {
        // MARK: - Real-Time Resources (Deduplication Only)
        
        /// Real-time stop monitoring for a given stop ID (deduplication only, not cached).
        case stopMonitoring(String)
        /// Real-time vehicle monitoring (deduplication only, not cached).
        case vehicleMonitoring
        /// Real-time alerts (deduplication only, not cached).
        case alerts
        /// Real-time alert messages only (deduplication only, not cached).
        case alertMessages
        /// Real-time cancellations only (deduplication only, not cached).
        case alertCancellations
        
        // MARK: - GTFS Static Resources (Cached)
        
        /// All routes from GTFS `routes.txt`.
        case routes
        /// All stops from GTFS `stops.txt`.
        case stops
        /// All trips from GTFS `trips.txt`.
        case trips
        /// Trips filtered by route ID.
        case tripsForRoute(String)
        /// All stop times from GTFS `stop_times.txt`.
        case stopTimes
        /// Stop times filtered by trip ID.
        case stopTimesForTrip(String)
        /// Stop times filtered by stop ID.
        case stopTimesForStop(String)
        /// Calendar date exceptions from GTFS `calendar_dates.txt`.
        case calendarDates
        /// All agencies from GTFS `agency.txt`.
        case agencies
        /// Service calendars from GTFS `calendar.txt`.
        case calendars
        /// Route IDs that have associated shapes.
        case shapeRouteIds
        /// Shape points for a specific shape ID.
        case shapePointsForShape(String)
        
        // MARK: - GeoJSON Resources (Deduplication Only)
        
        /// GeoJSON layers (deduplication only, not cached).
        case geoJSONLayers
        /// All points of interest (deduplication only, not cached).
        case geoJSONPOI
        /// Points of interest by category (deduplication only, not cached).
        case geoJSONPOICategory(String)
        /// Service boundaries with resolution and format (deduplication only, not cached).
        case geoJSONBounds(resolution: String, format: String)
    }
}
