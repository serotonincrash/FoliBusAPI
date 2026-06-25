//
//  FoliClient+Routes.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Routes (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    
    /// Fetch the complete list of all known routes from GTFS
    /// - Returns: An array of all routes
    internal func fetchRoutesFromNetwork() async throws -> [Foli.Route] {
        try await performDeduplicated(.routes) { [self] in
            let routeList = try await requestGTFS("/routes", as: Foli.RouteList.self)
            return routeList.routes
        }
    }
    
    /// Fetch a specific route by its ID
    /// - Parameter routeID: The ID of route to fetch.
    /// - Returns: The route if found
    func fetchRoute(id routeID: String) async throws -> Foli.Route? {
        _ = try await fetchRoutes()
        return await indexedRoute(for: routeID)
    }
    
    /// Fetch routes that match a given line reference (e.g., "15")
    /// - Parameter lineRef: The line reference to search for
    /// - Returns: Array of matching routes
    func fetchRoutes(for lineRef: String) async throws -> [Foli.Route] {
        _ = try await fetchRoutes()
        return await indexedRoutes(forShortName: lineRef)
    }
    
    // MARK: - Routes with Caching
    
    /// Fetch routes using the client's configured caching behavior.
    /// - Returns: Array of Route objects.
    func fetchRoutes() async throws -> [Foli.Route] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadRoutes() {
                await rebuildRouteIndexes(using: cached)
                return cached
            }
            // fallthrough to fetch
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleRoutes() {
                await rebuildRouteIndexes(using: staleCached)
                refreshCacheInBackground(
                    for: .routes,
                    fetch: { [self] in try await fetchRoutesFromNetwork() },
                    save: { [cache] routes in try await cache?.saveRoutes(routes) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let routes = try await fetchRoutesFromNetwork()
            await rebuildRouteIndexes(using: routes)
            try? await cache?.saveRoutes(routes)
            return routes
            
        case .cachedOnly:
            guard let cached = try await cache?.loadRoutes() else {
                throw Foli.APIError.noData
            }
            await rebuildRouteIndexes(using: cached)
            return cached
            
        case .noCache:
            let routes = try await fetchRoutesFromNetwork()
            await rebuildRouteIndexes(using: routes)
            return routes
        }
    }
}
