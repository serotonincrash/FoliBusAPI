//
//  FoliService+Stops.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation
import FoliBusAPI

// MARK: - Stops API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all stops from the API
    /// - Returns: Array of all stops
    func fetchStops() async throws -> [Foli.Stop] {
        return try await client.fetchStops()
    }
    
    /// Fetch a specific stop by ID.
    /// - Parameter stopId: The stop ID to fetch.
    /// - Returns: The stop if found.
    /// - Throws: ``Foli/APIError/notFound`` if no stop matches the ID.
    func fetchStop(id stopId: String) async throws -> Foli.Stop {
        guard let stop = try await client.stop(for: stopId) else {
            throw Foli.APIError.notFound
        }
        return stop
    }
    
}
