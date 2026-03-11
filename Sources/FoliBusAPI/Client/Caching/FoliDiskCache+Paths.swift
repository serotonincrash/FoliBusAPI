import Foundation

public extension Foli.DiskCache {
    internal func fileURL(for type: Foli.CacheResource) -> URL {
        let filename: String

        switch type {
        case .routes:
            filename = "routes.json"
        case .stops:
            filename = "stops.json"
        case .trips:
            filename = "trips.json"
        case .tripsForRoute(let routeId):
            filename = "trips_route_\(routeId).json"
        case .stopTimes:
            filename = "stop_times.json"
        case .stopTimesForTrip(let tripId):
            filename = "stop_times_trip_\(tripId).json"
        case .stopTimesForStop(let stopId):
            filename = "stop_times_stop_\(stopId).json"
        case .calendarDates:
            filename = "calendar_dates.json"
        }

        return cacheDirectory.appendingPathComponent(filename)
    }
}
