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
    @available(*, deprecated, message: "Use .resource(.routes) instead")
    static var routes: Foli.DedupeKey { .resource(.routes) }
    @available(*, deprecated, message: "Use .resource(.stops) instead")
    static var stops: Foli.DedupeKey { .resource(.stops) }
    @available(*, deprecated, message: "Use .resource(.trips) instead")
    static var trips: Foli.DedupeKey { .resource(.trips) }
    @available(*, deprecated, message: "Use .resource(.agencies) instead")
    static var agencies: Foli.DedupeKey { .resource(.agencies) }
    @available(*, deprecated, message: "Use .resource(.calendars) instead")
    static var calendars: Foli.DedupeKey { .resource(.calendars) }
    @available(*, deprecated, message: "Use .resource(.calendarDates) instead")
    static var calendarDates: Foli.DedupeKey { .resource(.calendarDates) }
    @available(*, deprecated, message: "Use .resource(.stopTimes) instead")
    static var stopTimes: Foli.DedupeKey { .resource(.stopTimes) }
    @available(*, deprecated, message: "Use .resource(.shapeRouteIds) instead")
    static var shapeRouteIds: Foli.DedupeKey { .resource(.shapeRouteIds) }
    @available(*, deprecated, message: "Use .resource(.geoJSONLayers) instead")
    static var geoJSONLayers: Foli.DedupeKey { .resource(.geoJSONLayers) }
    @available(*, deprecated, message: "Use .resource(.geoJSONPOI) instead")
    static var geoJSONPOI: Foli.DedupeKey { .resource(.geoJSONPOI) }

    @available(*, deprecated, message: "Use .resource(.tripsForRoute(_:)) instead")
    static func tripsForRoute(_ routeId: String) -> Foli.DedupeKey { .resource(.tripsForRoute(routeId)) }
    @available(*, deprecated, message: "Use .resource(.stopTimesForTrip(_:)) instead")
    static func stopTimesForTrip(_ tripId: String) -> Foli.DedupeKey { .resource(.stopTimesForTrip(tripId)) }
    @available(*, deprecated, message: "Use .resource(.stopTimesForStop(_:)) instead")
    static func stopTimesForStop(_ stopId: String) -> Foli.DedupeKey { .resource(.stopTimesForStop(stopId)) }
    @available(*, deprecated, message: "Use .resource(.shapePointsForShape(_:)) instead")
    static func shapePointsForShape(_ shapeId: String) -> Foli.DedupeKey { .resource(.shapePointsForShape(shapeId)) }
    @available(*, deprecated, message: "Use .resource(.geoJSONPOICategory(_:)) instead")
    static func geoJSONPOICategory(_ category: String) -> Foli.DedupeKey { .resource(.geoJSONPOICategory(category)) }
    @available(*, deprecated, message: "Use .resource(.geoJSONBounds(resolution:format:)) instead")
    static func geoJSONBounds(resolution: String, format: String) -> Foli.DedupeKey { .resource(.geoJSONBounds(resolution: resolution, format: format)) }
}
