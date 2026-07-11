//
//  FoliClient+Arrivals.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Arrivals

public extension FoliClient {
    
    /// Fetch arrivals for a stop identified by string ID.
    /// - Parameter stopId: The stop ID to monitor.
    /// - Returns: Array of vehicle arrivals.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        let response = try await fetchStopMonitoring(for: stopId)
        guard response.isValid else {
            throw Foli.APIError.serverError(response.status.rawValue)
        }
        return response.result
    }
    
    /// Fetch arrivals for a stop identified by numeric ID.
    /// - Parameter stopId: The numeric stop ID to monitor.
    /// - Returns: Array of vehicle arrivals.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await fetchArrivals(for: String(stopId))
    }
}

extension FoliClient {
    
    /// Fetch stop-monitoring data for a stop identified by string ID.
    /// - Parameter stopId: The stop ID to query.
    /// - Returns: A stop-monitoring response containing arrivals and departures.
    /// - Note: This is an internal method. Use `fetchArrivals(for:)` for the public API.
    internal func fetchStopMonitoring(for stopId: String) async throws -> Foli.ArrivalResponse {
        try await dedup.performDeduplicated(forKey: .stopMonitoring(stopId)) { [self] in
            try await requestSIRI("/sm/\(stopId)", as: Foli.ArrivalResponse.self)
        }
    }
    
    /// Fetch stop-monitoring data for a stop identified by numeric ID.
    /// - Parameter stopId: The numeric stop ID to query.
    /// - Returns: A stop-monitoring response containing arrivals and departures.
    /// - Note: This is an internal method. Use `fetchArrivals(for:)` for the public API.
    internal func fetchStopMonitoring(for stopId: Int) async throws -> Foli.ArrivalResponse {
        return try await fetchStopMonitoring(for: String(stopId))
    }
}
