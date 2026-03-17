//
//  FoliClient+Arrivals.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation
// MARK: - Arrivals

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch stop-monitoring data for a stop identified by string ID.
    /// - Parameter stopId: The stop ID to query.
    /// - Returns: A stop-monitoring response containing arrivals and departures.
    func fetchStopMonitoring(for stopId: String) async throws -> Foli.ArrivalResponse {
        try await performDeduplicated(.stopMonitoring(stopId)) { [self] in
            try await requestSIRI("/sm/\(stopId)", as: Foli.ArrivalResponse.self)
        }
    }
    
    /// Fetch arrivals for a stop identified by string ID.
    /// - Parameter stopId: The stop ID to monitor.
    /// - Returns: Array of vehicle arrivals.
    func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        let response = try await fetchStopMonitoring(for: stopId)
        guard response.isValid else {
            throw Foli.APIError.serverError(response.status)
        }
        return response.result
    }
}
