//
//  FoliService+Stops.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Stops API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all stops from the API
    /// - Returns: Array of all stops
    func fetchStops() async throws -> [Foli.Stop] {
        return try await client.fetchStops()
    }
    
    /// Fetch a specific stop by ID
    /// - Parameter stopId: The stop ID to fetch
    /// - Returns: The stop if found
    func fetchStop(id stopId: String) async throws -> Foli.Stop {
        guard let stop = try await client.fetchStop(byId: stopId) else {
            throw Foli.APIError.noData
        }
        return stop
    }
    
    func fetchStop(id stopId: Int) async throws -> Foli.Stop {
        return try await fetchStop(id: String(stopId))
    }
    
    // MARK: - Convenience Methods
    
    /// Sort stops by name
    func sortedStops(_ stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.sorted { $0.stopName < $1.stopName }
    }
    
    /// Sort stops by ID
    func sortedStopsById(_ stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.sorted { $0.id < $1.id }
    }
    
    /// Search stops by name or ID
    func searchStops(query: String, in stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.filter { stop in
            stop.stopName.localizedCaseInsensitiveContains(query) || stop.id.contains(query)
        }.sorted { $0.stopName < $1.stopName }
    }
    
}
