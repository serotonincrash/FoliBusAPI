import Foundation

/// Owns the lookup dictionaries used by ``FoliClient`` to resolve entities by ID.
///
/// Extracting these into a dedicated actor means index rebuilds (O(N) CPU work)
/// no longer block unrelated ``FoliClient`` calls, since they execute on the
/// indexes actor's executor rather than the client's.
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

    /// When each index was last rebuilt from its complete collection, keyed by that
    /// collection's resource (`.stops`, `.routes`, `.agencies`, `.calendars`, `.trips`).
    /// A rebuild whose fingerprint is unchanged still counts: the data was re-confirmed.
    /// Route-scoped trip merges never stamp `.trips`, since they are partial.
    private var rebuiltAt: [Foli.Resource: ContinuousClock.Instant] = [:]

    /// Whether `resource`'s index was rebuilt from its complete collection within
    /// `window`. A fresh index answers lookups authoritatively, misses included.
    func isFresh(_ resource: Foli.Resource, within window: Duration) -> Bool {
        guard let rebuiltAt = rebuiltAt[resource] else { return false }
        return ContinuousClock.now - rebuiltAt <= window
    }

    /// Forgets rebuild times so the next lookup goes back through the cache;
    /// `nil` forgets all of them. The indexed values themselves are kept.
    func invalidate(_ resource: Foli.Resource? = nil) {
        if let resource {
            rebuiltAt[resource] = nil
        } else {
            rebuiltAt.removeAll()
        }
    }

    /// Returns a stable hash of the items for cheap idempotency checks.
    /// Uses the elements' synthesized `Hashable` conformance, so any field-level
    /// change (not just an ID change) produces a different fingerprint.
    private func fingerprint<H: Hashable>(_ items: [H]) -> Int {
        var hasher = Hasher()
        hasher.combine(items)
        return hasher.finalize()
    }

    func rebuildStops(using stops: [Foli.Stop]) {
        rebuiltAt[.stops] = .now
        let fp = fingerprint(stops)
        guard fp != lastStopsFp else { return }
        lastStopsFp = fp
        stopsByID = Dictionary(stops.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
    }

    func rebuildRoutes(using routes: [Foli.Route]) {
        rebuiltAt[.routes] = .now
        let fp = fingerprint(routes)
        guard fp != lastRoutesFp else { return }
        lastRoutesFp = fp
        routesByID = Dictionary(routes.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        routesByShortName = Dictionary(grouping: routes, by: \Foli.Route.shortName)
    }

    func rebuildAgencies(using agencies: [Foli.Agency]) {
        rebuiltAt[.agencies] = .now
        let fp = fingerprint(agencies)
        guard fp != lastAgenciesFp else { return }
        lastAgenciesFp = fp
        agenciesByID = Dictionary(agencies.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
    }

    func rebuildCalendars(using calendars: [Foli.Calendar]) {
        rebuiltAt[.calendars] = .now
        let fp = fingerprint(calendars)
        guard fp != lastCalendarsFp else { return }
        lastCalendarsFp = fp
        calendarsByID = Dictionary(calendars.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
    }

    func rebuildTrips(using trips: [Foli.Trip]) {
        rebuiltAt[.trips] = .now
        let fp = fingerprint(trips)
        guard fp != lastTripsFp else { return }
        lastTripsFp = fp
        tripsByID = Dictionary(trips.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
    }

    /// Merges trips into the index without discarding existing entries.
    ///
    /// Used by route-scoped fetches, whose partial results must not replace the
    /// global trips index the way ``rebuildTrips(using:)`` does.
    func mergeTrips(_ newTrips: [Foli.Trip]) {
        guard !newTrips.isEmpty else { return }
        for trip in newTrips {
            tripsByID[trip.id] = trip
        }
        // The index no longer matches any full-rebuild fingerprint.
        lastTripsFp = nil
    }

    func stop(for id: String) -> Foli.Stop? { stopsByID[id] }
    func route(for id: String) -> Foli.Route? { routesByID[id] }
    func routes(forShortName shortName: String) -> [Foli.Route] { routesByShortName[shortName] ?? [] }
    func agency(for id: String) -> Foli.Agency? { agenciesByID[id] }
    func calendar(for serviceId: String) -> Foli.Calendar? { calendarsByID[serviceId] }
    func trip(for tripId: String) -> Foli.Trip? { tripsByID[tripId] }
}
