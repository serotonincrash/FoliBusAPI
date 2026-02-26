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
    func fetchRoutes() async throws -> [Foli.Route] {
        let url = try makeGTFSEndpointURL(path: "/routes")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            let routeList = try JSONDecoder().decode(FoliRouteList.self, from: data)
            return routeList.routes
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch a specific route by its ID
    /// - Parameter routeId: The ID of route to fetch
    /// - Returns: The route if found
    func fetchRoute(byId routeId: String) async throws -> Foli.Route? {
        let routes = try await fetchRoutes()
        return routes.first { $0.id == routeId }
    }
    
    /// Fetch routes that match a given line reference (e.g., "15")
    /// - Parameter lineRef: The line reference to search for
    /// - Returns: Array of matching routes
    func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        let routes = try await fetchRoutes()
        return routes.filter { $0.shortName == lineRef }
    }
}
