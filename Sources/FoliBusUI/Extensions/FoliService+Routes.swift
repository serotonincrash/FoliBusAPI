//
//  FoliService+Routes.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation
import FoliBusAPI

// MARK: - Routes API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all routes from the API
    /// - Returns: Array of all routes
    func fetchRoutes() async throws -> [Foli.Route] {
        return try await client.fetchRoutes()
    }
    
    /// Fetch a specific route by ID.
    /// - Parameter routeId: The route ID to fetch.
    /// - Returns: The route if found.
    /// - Throws: ``Foli/APIError/notFound`` if no route matches the ID.
    func fetchRoute(id routeId: String) async throws -> Foli.Route {
        guard let route = try await client.route(for: routeId) else {
            throw Foli.APIError.notFound
        }
        return route
    }
    
    /// Fetch routes matching a specific line reference
    /// - Parameter lineRef: The line reference (e.g., "15")
    /// - Returns: Array of matching routes
    func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        return try await client.fetchRoutes(for: lineRef)
    }
    
}
