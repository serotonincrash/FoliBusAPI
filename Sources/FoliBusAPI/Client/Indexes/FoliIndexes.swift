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

    /// Fingerprint of the last array passed to ``rebuildStops(using:)``.
    private var lastStopsFp: Int?
    /// Fingerprint of the last array passed to ``rebuildRoutes(using:)``.
    private var lastRoutesFp: Int?
    /// Fingerprint of the last array passed to ``rebuildAgencies(using:)``.
    private var lastAgenciesFp: Int?
    /// Fingerprint of the last array passed to ``rebuildCalendars(using:)``.
    private var lastCalendarsFp: Int?
    /// Fingerprint of the last array passed to ``rebuildTrips(using:)``.
    private var lastTripsFp: Int?

    /// Returns a stable hash of the items for cheap idempotency checks.
    /// Uses the elements' synthesized `Hashable` conformance, so any field-level
    /// change (not just an ID change) produces a different fingerprint.
    private func fingerprint<H: Hashable>(_ items: [H]) -> Int {
        var hasher = Hasher()
        hasher.combine(items)
        return hasher.finalize()
    }

    func rebuildStops(using stops: [Foli.Stop]) {
        let fp = fingerprint(stops)
        guard fp != lastStopsFp else { return }
        lastStopsFp = fp
        stopsByID = Dictionary(uniqueKeysWithValues: stops.map { ($0.id, $0) })
    }

    func rebuildRoutes(using routes: [Foli.Route]) {
        let fp = fingerprint(routes)
        guard fp != lastRoutesFp else { return }
        lastRoutesFp = fp
        routesByID = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        routesByShortName = Dictionary(grouping: routes, by: \Foli.Route.shortName)
    }

    func rebuildAgencies(using agencies: [Foli.Agency]) {
        let fp = fingerprint(agencies)
        guard fp != lastAgenciesFp else { return }
        lastAgenciesFp = fp
        agenciesByID = Dictionary(uniqueKeysWithValues: agencies.map { ($0.id, $0) })
    }

    func rebuildCalendars(using calendars: [Foli.Calendar]) {
        let fp = fingerprint(calendars)
        guard fp != lastCalendarsFp else { return }
        lastCalendarsFp = fp
        calendarsByID = Dictionary(uniqueKeysWithValues: calendars.map { ($0.id, $0) })
    }

    func rebuildTrips(using trips: [Foli.Trip]) {
        let fp = fingerprint(trips)
        guard fp != lastTripsFp else { return }
        lastTripsFp = fp
        tripsByID = Dictionary(uniqueKeysWithValues: trips.map { ($0.id, $0) })
    }

    func stop(for id: String) -> Foli.Stop? { stopsByID[id] }
    func route(for id: String) -> Foli.Route? { routesByID[id] }
    func routes(forShortName shortName: String) -> [Foli.Route] { routesByShortName[shortName] ?? [] }
    func agency(for id: String) -> Foli.Agency? { agenciesByID[id] }
    func calendar(for serviceId: String) -> Foli.Calendar? { calendarsByID[serviceId] }
    func trip(for tripId: String) -> Foli.Trip? { tripsByID[tripId] }
}
