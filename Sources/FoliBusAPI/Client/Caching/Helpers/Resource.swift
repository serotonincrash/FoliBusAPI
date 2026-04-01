import Foundation

// MARK: - Cache Resource Keys
public extension Foli {
    /// Identifies a cacheable (or deduplication-keyed) resource from the Föli API.
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
    enum Resource: Hashable, Sendable {
        // MARK: - Real-Time Resources (Deduplication Only)
        
        /// Real-time stop monitoring for a given stop ID (not cached).
        case stopMonitoring(String)
        /// Real-time vehicle monitoring (not cached).
        case vehicleMonitoring
        /// Real-time alerts (not cached).
        case alerts
        /// Real-time alert messages only (not cached).
        case alertMessages
        /// Real-time cancellations only (not cached).
        case alertCancellations
        
        // MARK: - GTFS Static Resources (Cached)
        
        /// All routes from GTFS `routes.txt`. Retrieves from cache if cache behavior is set accordingly.
        case routes
        /// All stops from GTFS `stops.txt`. Retrieves from cache if cache behavior is set accordingly.
        case stops
        /// All trips from GTFS `trips.txt`. Retrieves from cache if cache behavior is set accordingly.
        case trips
        /// Trips filtered by route ID. Retrieves from cache if cache behavior is set accordingly.
        case tripsForRoute(String)
        /// All stop times from GTFS `stop_times.txt`. Retrieves from cache if cache behavior is set accordingly.
        case stopTimes
        /// Stop times filtered by trip ID. Retrieves from cache if cache behavior is set accordingly.
        case stopTimesForTrip(String)
        /// Stop times filtered by stop ID.
        case stopTimesForStop(String)
        /// Calendar date exceptions from GTFS `calendar_dates.txt`. Retrieves from cache if cache behavior is set accordingly.
        case calendarDates
        /// All agencies from GTFS `agency.txt`. Retrieves from cache if cache behavior is set accordingly.
        case agencies
        /// Service calendars from GTFS `calendar.txt`. Retrieves from cache if cache behavior is set accordingly.
        case calendars
        /// Route IDs that have associated shapes. Retrieves from cache if cache behavior is set accordingly.
        case shapeRouteIds
        /// Shape points for a specific shape ID. Retrieves from cache if cache behavior is set accordingly.
        case shapePointsForShape(String)
        
        // MARK: - GeoJSON Resources (Deduplication Only)
        
        /// GeoJSON layers (not cached).
        case geoJSONLayers
        /// All points of interest (not cached).
        case geoJSONPOI
        /// Points of interest by category (not cached).
        case geoJSONPOICategory(String)
        /// Service boundaries with resolution and format (not cached).
        case geoJSONBounds(resolution: String, format: String)
    }
}
