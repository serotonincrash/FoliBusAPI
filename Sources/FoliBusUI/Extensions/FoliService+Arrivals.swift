//
//  FoliService+Arrivals.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation
import FoliBusAPI

// MARK: - Arrivals API

public extension FoliService {
    
    /// Fetch arrivals for a specific stop
    /// - Parameter stopId: The stop ID
    /// - Returns: Array of arrivals for the stop
    func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
}

