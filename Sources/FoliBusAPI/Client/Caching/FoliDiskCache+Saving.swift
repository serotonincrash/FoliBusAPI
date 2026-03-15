import Foundation

public extension Foli.DiskCache {
    func saveRoutes(_ routes: [Foli.Route]) async throws {
        try await save(routes, type: .routes)
    }

    func saveStops(_ stops: [Foli.Stop]) async throws {
        try await save(stops, type: .stops)
    }

    func saveTrips(_ trips: [Foli.Trip]) async throws {
        try await save(trips, type: .trips)
    }

    func saveTrips(_ trips: [Foli.Trip], forRoute routeId: String) async throws {
        try await save(trips, type: .tripsForRoute(routeId))
    }

    func saveStopTimes(_ stopTimes: [Foli.StopTime]) async throws {
        try await save(stopTimes, type: .stopTimes)
    }

    func saveStopTimes(_ stopTimes: [Foli.StopTime], forTrip tripId: String) async throws {
        try await save(stopTimes, type: .stopTimesForTrip(tripId))
    }

    func saveStopTimes(_ stopTimes: [Foli.StopTime], forStop stopId: String) async throws {
        try await save(stopTimes, type: .stopTimesForStop(stopId))
    }

    func saveCalendarDates(_ calendarDates: [Foli.CalendarDate]) async throws {
        try await save(calendarDates, type: .calendarDates)
    }

    func saveAgencies(_ agencies: [Foli.Agency]) async throws {
        try await save(agencies, type: .agencies)
    }

    func saveCalendars(_ calendars: [Foli.Calendar]) async throws {
        try await save(calendars, type: .calendars)
    }

    func saveShapeRouteIds(_ routeIds: [String]) async throws {
        try await save(routeIds, type: .shapeRouteIds)
    }

    func saveShapePoints(_ shapePoints: [Foli.ShapePoint], forShape shapeId: String) async throws {
        try await save(shapePoints, type: .shapePointsForShape(shapeId))
    }

    internal func save<T: Codable>(_ value: T, type: Foli.CacheResource) async throws {
        let datasetId = try await fetchLatestDatasetId()

        let metadata = DatasetMetadata(
            datasetId: datasetId,
            cachedAt: Date()
        )

        let cachedData = CachedData(metadata: metadata, data: value)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(cachedData)

        let fileURL = fileURL(for: type)
        try data.write(to: fileURL, options: .atomic)
    }
}
