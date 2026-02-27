//
//  FoliService+Routes.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Routes API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all routes from the API
    /// - Returns: Array of all routes
    func fetchRoutes() async throws -> [Foli.Route] {
        return try await client.fetchRoutes()
    }
    
    /// Fetch a specific route by ID
    /// - Parameter routeId: The route ID to fetch
    /// - Returns: The route if found
    func fetchRoute(id routeId: String) async throws -> Foli.Route {
        guard let route = try await client.fetchRoute(byId: routeId) else {
            throw Foli.APIError.noData
        }
        return route
    }
    
    func fetchRoute(id routeId: Int) async throws -> Foli.Route {
        return try await fetchRoute(id: String(routeId))
    }
    
    /// Fetch routes matching a specific line reference
    /// - Parameter lineRef: The line reference (e.g., "15")
    /// - Returns: Array of matching routes
    func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        return try await client.fetchRoutes(byLineRef: lineRef)
    }
    
}
