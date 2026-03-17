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
        guard let stop = try await client.fetchStop(for: stopId) else {
            throw Foli.APIError.noData
        }
        return stop
    }
    
    /// Fetch a specific stop by numeric ID.
    /// - Parameter stopId: The stop ID to fetch.
    /// - Returns: The stop if found.
    /// - Note: All GTFS stop IDs are strings. Prefer ``fetchStop(id:)-2brmk`` with a `String` argument.
    @available(*, deprecated, message: "GTFS stop IDs are strings. Use fetchStop(id:) with a String argument instead.")
    func fetchStop(id stopId: Int) async throws -> Foli.Stop {
        return try await fetchStop(id: String(stopId))
    }
    
    // MARK: - Convenience Methods (Deprecated)
    
    /// Sort stops by name.
    /// - Parameter stops: The stops to sort.
    /// - Returns: Stops sorted by name.
    /// - Note: Prefer calling `stops.sortedByName()` directly on the collection.
    @available(*, deprecated, message: "Call sortedByName() directly on the [Foli.Stop] collection instead.")
    func sortedStops(_ stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.sortedByName()
    }
    
    /// Sort stops by ID.
    /// - Parameter stops: The stops to sort.
    /// - Returns: Stops sorted by ID.
    /// - Note: Prefer calling `stops.sortedByID()` directly on the collection.
    @available(*, deprecated, message: "Call sortedByID() directly on the [Foli.Stop] collection instead.")
    func sortedStopsById(_ stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.sortedByID()
    }
    
    /// Search stops by name or ID.
    /// - Parameters:
    ///   - query: The search string.
    ///   - stops: The stops to search.
    /// - Returns: Matching stops sorted by name.
    /// - Note: Prefer calling `stops.search(_:)` directly on the collection.
    @available(*, deprecated, message: "Call search(_:) directly on the [Foli.Stop] collection instead.")
    func searchStops(query: String, in stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.search(query)
    }
    
}
