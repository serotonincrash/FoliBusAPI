import Foundation

// MARK: - Typed Convenience Access
//
// Default-implemented shortcuts that delegate to the three generic
// `loadResource` / `loadStaleResource` / `saveResource` requirements.
// Call sites use these typed methods (`cache?.loadRoutes()` etc.) so
// that adding a new resource type is a one-line change here, not a
// protocol requirement + conformor method + mock stub.

extension Foli.Cache {
    // MARK: - Routes
    func loadRoutes() async throws -> [Foli.Route]? { try await loadResource([Foli.Route].self, forKey: .routes) }
    func loadStaleRoutes() async throws -> [Foli.Route]? { try await loadStaleResource([Foli.Route].self, forKey: .routes) }
    func saveRoutes(_ routes: [Foli.Route]) async throws { try await saveResource(routes, forKey: .routes) }

    // MARK: - Stops
    func loadStops() async throws -> [Foli.Stop]? { try await loadResource([Foli.Stop].self, forKey: .stops) }
    func loadStaleStops() async throws -> [Foli.Stop]? { try await loadStaleResource([Foli.Stop].self, forKey: .stops) }
    func saveStops(_ stops: [Foli.Stop]) async throws { try await saveResource(stops, forKey: .stops) }

    // MARK: - Trips
    func loadTrips() async throws -> [Foli.Trip]? { try await loadResource([Foli.Trip].self, forKey: .trips) }
    func loadStaleTrips() async throws -> [Foli.Trip]? { try await loadStaleResource([Foli.Trip].self, forKey: .trips) }
    func saveTrips(_ trips: [Foli.Trip]) async throws { try await saveResource(trips, forKey: .trips) }
    func loadTrips(forRoute routeId: String) async throws -> [Foli.Trip]? { try await loadResource([Foli.Trip].self, forKey: .tripsForRoute(routeId)) }
    func loadStaleTrips(forRoute routeId: String) async throws -> [Foli.Trip]? { try await loadStaleResource([Foli.Trip].self, forKey: .tripsForRoute(routeId)) }
    func saveTrips(_ trips: [Foli.Trip], forRoute routeId: String) async throws { try await saveResource(trips, forKey: .tripsForRoute(routeId)) }

    // MARK: - Stop Times
    func loadStopTimes() async throws -> [Foli.StopTime]? { try await loadResource([Foli.StopTime].self, forKey: .stopTimes) }
    func loadStaleStopTimes() async throws -> [Foli.StopTime]? { try await loadStaleResource([Foli.StopTime].self, forKey: .stopTimes) }
    func saveStopTimes(_ stopTimes: [Foli.StopTime]) async throws { try await saveResource(stopTimes, forKey: .stopTimes) }
    func loadStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? { try await loadResource([Foli.StopTime].self, forKey: .stopTimesForTrip(tripId)) }
    func loadStaleStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? { try await loadStaleResource([Foli.StopTime].self, forKey: .stopTimesForTrip(tripId)) }
    func saveStopTimes(_ stopTimes: [Foli.StopTime], forTrip tripId: String) async throws { try await saveResource(stopTimes, forKey: .stopTimesForTrip(tripId)) }
    func loadStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? { try await loadResource([Foli.StopTime].self, forKey: .stopTimesForStop(stopId)) }
    func loadStaleStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? { try await loadStaleResource([Foli.StopTime].self, forKey: .stopTimesForStop(stopId)) }
    func saveStopTimes(_ stopTimes: [Foli.StopTime], forStop stopId: String) async throws { try await saveResource(stopTimes, forKey: .stopTimesForStop(stopId)) }

    // MARK: - Calendar Dates
    func loadCalendarDates() async throws -> [Foli.CalendarDate]? { try await loadResource([Foli.CalendarDate].self, forKey: .calendarDates) }
    func loadStaleCalendarDates() async throws -> [Foli.CalendarDate]? { try await loadStaleResource([Foli.CalendarDate].self, forKey: .calendarDates) }
    func saveCalendarDates(_ calendarDates: [Foli.CalendarDate]) async throws { try await saveResource(calendarDates, forKey: .calendarDates) }

    // MARK: - Agencies
    func loadAgencies() async throws -> [Foli.Agency]? { try await loadResource([Foli.Agency].self, forKey: .agencies) }
    func loadStaleAgencies() async throws -> [Foli.Agency]? { try await loadStaleResource([Foli.Agency].self, forKey: .agencies) }
    func saveAgencies(_ agencies: [Foli.Agency]) async throws { try await saveResource(agencies, forKey: .agencies) }

    // MARK: - Calendars
    func loadCalendars() async throws -> [Foli.Calendar]? { try await loadResource([Foli.Calendar].self, forKey: .calendars) }
    func loadStaleCalendars() async throws -> [Foli.Calendar]? { try await loadStaleResource([Foli.Calendar].self, forKey: .calendars) }
    func saveCalendars(_ calendars: [Foli.Calendar]) async throws { try await saveResource(calendars, forKey: .calendars) }

    // MARK: - Shapes
    func loadShapeRouteIds() async throws -> [String]? { try await loadResource([String].self, forKey: .shapeRouteIds) }
    func loadStaleShapeRouteIds() async throws -> [String]? { try await loadStaleResource([String].self, forKey: .shapeRouteIds) }
    func saveShapeRouteIds(_ routeIds: [String]) async throws { try await saveResource(routeIds, forKey: .shapeRouteIds) }
    func loadShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint]? { try await loadResource([Foli.ShapePoint].self, forKey: .shapePointsForShape(shapeId)) }
    func loadStaleShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint]? { try await loadStaleResource([Foli.ShapePoint].self, forKey: .shapePointsForShape(shapeId)) }
    func saveShapePoints(_ shapePoints: [Foli.ShapePoint], forShape shapeId: String) async throws { try await saveResource(shapePoints, forKey: .shapePointsForShape(shapeId)) }
}
