import Foundation

// MARK: - Index Access
//
// Thin forwarders to `indexes` (``FoliIndexes``). Rebuild methods are called
// from `resolveCached`'s `rebuildIndex` closure; lookup methods are called
// from the public `fetchX(id:)` helpers.

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    internal func rebuildStopIndex(using stops: [Foli.Stop]) async {
        await indexes.rebuildStops(using: stops)
    }

    internal func rebuildRouteIndexes(using routes: [Foli.Route]) async {
        await indexes.rebuildRoutes(using: routes)
    }

    internal func rebuildAgencyIndex(using agencies: [Foli.Agency]) async {
        await indexes.rebuildAgencies(using: agencies)
    }

    internal func rebuildCalendarIndex(using calendars: [Foli.Calendar]) async {
        await indexes.rebuildCalendars(using: calendars)
    }

    internal func rebuildTripIndex(using trips: [Foli.Trip]) async {
        await indexes.rebuildTrips(using: trips)
    }

    internal func indexedStop(for stopId: String) async -> Foli.Stop? {
        await indexes.stop(for: stopId)
    }

    internal func indexedRoute(for routeId: String) async -> Foli.Route? {
        await indexes.route(for: routeId)
    }

    internal func indexedRoutes(forShortName shortName: String) async -> [Foli.Route] {
        await indexes.routes(forShortName: shortName)
    }

    internal func indexedAgency(for agencyId: String) async -> Foli.Agency? {
        await indexes.agency(for: agencyId)
    }

    internal func indexedCalendar(for serviceId: String) async -> Foli.Calendar? {
        await indexes.calendar(for: serviceId)
    }

    internal func indexedTrip(for tripId: String) async -> Foli.Trip? {
        await indexes.trip(for: tripId)
    }
}
