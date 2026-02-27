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
    
    func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await fetchArrivals(for: String(stopId))
    }
    
}

