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

// Convenience statics mirror old Foli.Resource case names so existing
// call sites (dedup.performDeduplicated(.routes)) compile unchanged.
public extension Foli.DedupeKey {
    static var routes: Foli.DedupeKey { .resource(.routes) }
    static var stops: Foli.DedupeKey { .resource(.stops) }
    static var trips: Foli.DedupeKey { .resource(.trips) }
    static var agencies: Foli.DedupeKey { .resource(.agencies) }
    static var calendars: Foli.DedupeKey { .resource(.calendars) }
    static var calendarDates: Foli.DedupeKey { .resource(.calendarDates) }
    static var stopTimes: Foli.DedupeKey { .resource(.stopTimes) }
    static var shapeRouteIds: Foli.DedupeKey { .resource(.shapeRouteIds) }
    static var geoJSONLayers: Foli.DedupeKey { .resource(.geoJSONLayers) }
    static var geoJSONPOI: Foli.DedupeKey { .resource(.geoJSONPOI) }

    static func tripsForRoute(_ routeId: String) -> Foli.DedupeKey { .resource(.tripsForRoute(routeId)) }
    static func stopTimesForTrip(_ tripId: String) -> Foli.DedupeKey { .resource(.stopTimesForTrip(tripId)) }
    static func stopTimesForStop(_ stopId: String) -> Foli.DedupeKey { .resource(.stopTimesForStop(stopId)) }
    static func shapePointsForShape(_ shapeId: String) -> Foli.DedupeKey { .resource(.shapePointsForShape(shapeId)) }
    static func geoJSONPOICategory(_ category: String) -> Foli.DedupeKey { .resource(.geoJSONPOICategory(category)) }
    static func geoJSONBounds(resolution: String, format: String) -> Foli.DedupeKey { .resource(.geoJSONBounds(resolution: resolution, format: format)) }
}
