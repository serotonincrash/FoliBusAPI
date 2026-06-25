import Foundation

// MARK: - Cache Resource Keys
public extension Foli {
    /// Identifies a cacheable resource from the Föli API.
    ///
    /// Used as keys for cache operations (load, save, clear).
    /// For request deduplication, see ``DedupeKey``.
    ///
    /// ## Example
    /// ```swift
    /// let routes = try await client.fetchRoutes()  // Cached with .routes key
    /// ```
    enum Resource: Hashable, Sendable {
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
        
        // MARK: - GeoJSON Resources (Cached)
        
        /// GeoJSON layers. Retrieves from cache if cache behavior is set accordingly.
        case geoJSONLayers
        /// All points of interest. Retrieves from cache if cache behavior is set accordingly.
        case geoJSONPOI
        /// Points of interest by category. Retrieves from cache if cache behavior is set accordingly.
        case geoJSONPOICategory(String)
        /// Service boundaries with resolution and format. Retrieves from cache if cache behavior is set accordingly.
        case geoJSONBounds(resolution: String, format: String)
    }
}
