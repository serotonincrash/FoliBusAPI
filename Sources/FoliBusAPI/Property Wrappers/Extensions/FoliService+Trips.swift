//
//  FoliService+Trips.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Trips API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all trips from the GTFS API
    /// - Returns: Array of all trips
    func fetchTrips() async throws -> [Foli.Trip] {
        return try await client.fetchTrips()
    }
    
    /// Fetch trips for a specific route from the GTFS API
    /// - Parameter routeId: The ID of the route to fetch trips for
    /// - Returns: Array of trips belonging to the specified route
    func fetchTrips(forRoute routeId: String) async throws -> [Foli.Trip] {
        return try await client.fetchTrips(forRoute: routeId)
    }
}
