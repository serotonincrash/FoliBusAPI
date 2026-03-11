import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    internal func rebuildStopIndex(using stops: [Foli.Stop]) {
        stopsByID = Dictionary(uniqueKeysWithValues: stops.map { ($0.id, $0) })
    }

    internal func rebuildRouteIndexes(using routes: [Foli.Route]) {
        routesByID = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        routesByShortName = Dictionary(grouping: routes, by: \Foli.Route.shortName)
    }

    internal func indexedStop(for stopId: String) -> Foli.Stop? {
        stopsByID[stopId]
    }

    internal func indexedRoute(for routeId: String) -> Foli.Route? {
        routesByID[routeId]
    }

    internal func indexedRoutes(forShortName shortName: String) -> [Foli.Route] {
        routesByShortName[shortName] ?? []
    }
}
