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
        try await dedup.performDeduplicated(forKey: .resource(.routes)) { [self] in
            let routeList = try await requestGTFS("/routes", as: Foli.RouteList.self)
            return routeList.routes
        }
    }
    
    /// Fetch a specific route by its ID.
    ///
    /// The Foli API does not support individual route lookups — this method fetches all routes
    /// (cached) and performs an O(1) dictionary lookup.
    /// The first call populates the cache; subsequent calls are instant.
    ///
    /// - Parameter routeId: The ID of route to fetch.
    /// - Returns: The route if found
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func route(for routeId: String) async throws -> Foli.Route? {
        _ = try await fetchRoutes()
        return await indexes.route(for: routeId)
    }
    
    /// Fetch routes that match a given line reference (e.g., "15")
    /// - Parameter lineRef: The line reference to search for
    /// - Returns: Array of matching routes
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchRoutes(for lineRef: String) async throws -> [Foli.Route] {
        _ = try await fetchRoutes()
        return await indexes.routes(forShortName: lineRef)
    }
    
    // MARK: - Routes with Caching
    
    /// Fetch routes using the client's configured caching behavior.
    /// - Returns: Array of Route objects.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchRoutes() async throws -> [Foli.Route] {
        try await resolveCached(
            for: .routes,
            load: { [cache] in try await cache?.loadRoutes() },
            loadStale: { [cache] in try await cache?.loadStaleRoutes() },
            save: { [cache] routes in try await cache?.saveRoutes(routes) },
            fetch: { [self] in try await fetchRoutesFromNetwork() },
            rebuildIndex: { [self] routes in await indexes.rebuildRoutes(using: routes) }
        )
    }
}
