//
//  FoliService+Arrivals.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation
// MARK: - Arrivals API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch arrivals for a specific stop
    /// - Parameter stopId: The stop ID
    /// - Returns: Array of arrivals for the stop
    func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
    /// Fetch arrivals for a specific stop by numeric ID.
    /// - Parameter stopId: The numeric stop ID.
    /// - Returns: Array of arrivals for the stop.
    /// - Note: All GTFS stop IDs are strings. Prefer ``fetchArrivals(for:)-9p5gt`` with a `String` argument.
    @available(*, deprecated, message: "GTFS stop IDs are strings. Use fetchArrivals(for:) with a String argument instead.")
    func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await fetchArrivals(for: String(stopId))
    }
    
}

