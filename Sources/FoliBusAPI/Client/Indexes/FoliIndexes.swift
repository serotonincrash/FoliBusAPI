import Foundation

/// Owns the lookup dictionaries used by ``FoliClient`` to resolve entities by ID.
///
/// Extracting these into a dedicated actor means index rebuilds (O(N) CPU work)
/// no longer block unrelated ``FoliClient`` calls, since they execute on the
/// indexes actor's executor rather than the client's.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
internal actor FoliIndexes {
    private var stopsByID: [String: Foli.Stop] = [:]
    private var routesByID: [String: Foli.Route] = [:]
    private var routesByShortName: [String: [Foli.Route]] = [:]
    private var agenciesByID: [String: Foli.Agency] = [:]
    private var calendarsByID: [String: Foli.Calendar] = [:]
    private var tripsByID: [String: Foli.Trip] = [:]

    func rebuildStops(using stops: [Foli.Stop]) {
        stopsByID = Dictionary(uniqueKeysWithValues: stops.map { ($0.id, $0) })
    }

    func rebuildRoutes(using routes: [Foli.Route]) {
        routesByID = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        routesByShortName = Dictionary(grouping: routes, by: \Foli.Route.shortName)
    }

    func rebuildAgencies(using agencies: [Foli.Agency]) {
        agenciesByID = Dictionary(uniqueKeysWithValues: agencies.map { ($0.id, $0) })
    }

    func rebuildCalendars(using calendars: [Foli.Calendar]) {
        calendarsByID = Dictionary(uniqueKeysWithValues: calendars.map { ($0.id, $0) })
    }

    func rebuildTrips(using trips: [Foli.Trip]) {
        tripsByID = Dictionary(uniqueKeysWithValues: trips.map { ($0.id, $0) })
    }

    func stop(for id: String) -> Foli.Stop? { stopsByID[id] }
    func route(for id: String) -> Foli.Route? { routesByID[id] }
    func routes(forShortName shortName: String) -> [Foli.Route] { routesByShortName[shortName] ?? [] }
    func agency(for id: String) -> Foli.Agency? { agenciesByID[id] }
    func calendar(for serviceId: String) -> Foli.Calendar? { calendarsByID[serviceId] }
    func trip(for tripId: String) -> Foli.Trip? { tripsByID[tripId] }
}
