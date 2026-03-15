import Foundation

public extension Foli.DiskCache {
    func loadRoutes() async throws -> [Foli.Route]? {
        try await load(type: .routes)
    }

    func loadStaleRoutes() async throws -> [Foli.Route]? {
        try await loadIgnoringFreshness(type: .routes)
    }

    func loadStops() async throws -> [Foli.Stop]? {
        try await load(type: .stops)
    }

    func loadStaleStops() async throws -> [Foli.Stop]? {
        try await loadIgnoringFreshness(type: .stops)
    }

    func loadTrips() async throws -> [Foli.Trip]? {
        try await load(type: .trips)
    }

    func loadStaleTrips() async throws -> [Foli.Trip]? {
        try await loadIgnoringFreshness(type: .trips)
    }

    func loadTrips(forRoute routeId: String) async throws -> [Foli.Trip]? {
        try await load(type: .tripsForRoute(routeId))
    }

    func loadStaleTrips(forRoute routeId: String) async throws -> [Foli.Trip]? {
        try await loadIgnoringFreshness(type: .tripsForRoute(routeId))
    }

    func loadStopTimes() async throws -> [Foli.StopTime]? {
        try await load(type: .stopTimes)
    }

    func loadStaleStopTimes() async throws -> [Foli.StopTime]? {
        try await loadIgnoringFreshness(type: .stopTimes)
    }

    func loadStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? {
        try await load(type: .stopTimesForTrip(tripId))
    }

    func loadStaleStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? {
        try await loadIgnoringFreshness(type: .stopTimesForTrip(tripId))
    }

    func loadStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? {
        try await load(type: .stopTimesForStop(stopId))
    }

    func loadStaleStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? {
        try await loadIgnoringFreshness(type: .stopTimesForStop(stopId))
    }

    func loadCalendarDates() async throws -> [Foli.CalendarDate]? {
        try await load(type: .calendarDates)
    }

    func loadStaleCalendarDates() async throws -> [Foli.CalendarDate]? {
        try await loadIgnoringFreshness(type: .calendarDates)
    }

    func loadAgencies() async throws -> [Foli.Agency]? {
        try await load(type: .agencies)
    }

    func loadStaleAgencies() async throws -> [Foli.Agency]? {
        try await loadIgnoringFreshness(type: .agencies)
    }

    func loadCalendars() async throws -> [Foli.Calendar]? {
        try await load(type: .calendars)
    }

    func loadStaleCalendars() async throws -> [Foli.Calendar]? {
        try await loadIgnoringFreshness(type: .calendars)
    }

    func loadShapeRouteIds() async throws -> [String]? {
        try await load(type: .shapeRouteIds)
    }

    func loadStaleShapeRouteIds() async throws -> [String]? {
        try await loadIgnoringFreshness(type: .shapeRouteIds)
    }

    func loadShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint]? {
        try await load(type: .shapePointsForShape(shapeId))
    }

    func loadStaleShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint]? {
        try await loadIgnoringFreshness(type: .shapePointsForShape(shapeId))
    }

    func cacheAge(for type: Foli.CacheResource) async -> TimeInterval? {
        guard let metadata = try? await loadMetadata(for: type) else {
            return nil
        }
        return Date().timeIntervalSince(metadata.cachedAt)
    }

    internal func load<T: Codable>(type: Foli.CacheResource) async throws -> T? {
        guard await hasValidCache(for: type) else {
            return nil
        }

        return try await loadIgnoringFreshness(type: type)
    }

    internal func loadIgnoringFreshness<T: Codable>(type: Foli.CacheResource) async throws -> T? {
        let fileURL = fileURL(for: type)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)
        return cachedData.data
    }
}
