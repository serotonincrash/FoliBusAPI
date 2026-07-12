import Foundation

extension Foli.DiskCache {
    internal func fileURL(for type: Foli.Resource) throws -> URL {
        let filename: String

        switch type {
        case .routes:
            filename = "routes.json"
        case .stops:
            filename = "stops.json"
        case .trips:
            filename = "trips.json"
        case .tripsForRoute(let routeId):
            filename = "trips_route_\(sanitized(routeId)).json"
        case .stopTimes:
            filename = "stop_times.json"
        case .stopTimesForTrip(let tripId):
            filename = "stop_times_trip_\(sanitized(tripId)).json"
        case .stopTimesForStop(let stopId):
            filename = "stop_times_stop_\(sanitized(stopId)).json"
        case .calendarDates:
            filename = "calendar_dates.json"
        case .agencies:
            filename = "agencies.json"
        case .calendars:
            filename = "calendars.json"
        case .shapeRouteIds:
            filename = "shape_route_ids.json"
        case .shapePointsForShape(let shapeId):
            filename = "shape_points_\(sanitized(shapeId)).json"
        case .geoJSONLayers:
            filename = "geojson_layers.json"
        case .geoJSONPOI:
            filename = "geojson_poi.json"
        case .geoJSONPOICategory(let category):
            filename = "geojson_poi_\(sanitized(category)).json"
        case .geoJSONBounds(let resolution, let format):
            filename = "geojson_bounds_\(sanitized(resolution))_\(sanitized(format)).json"
        }

        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Percent-encodes every byte outside ASCII alphanumerics so identifiers taken from
    /// resource keys cannot introduce path separators or traversal sequences, and cannot
    /// collide with the `_`-delimited filename scheme (`_` itself is encoded).
    private func sanitized(_ component: String) -> String {
        var result = ""
        for byte in component.utf8 {
            let isASCIIAlphanumeric = (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
            if isASCIIAlphanumeric {
                result.append(Character(UnicodeScalar(byte)))
            } else {
                result.append(String(format: "%%%02X", byte))
            }
        }
        return result
    }
}
