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
    
    /// Fetch real-time arrival data for a specific stop
    /// - Parameter stopId: The ID of the stop to query
    /// - Returns: Stop monitoring response with arrival/departure information
    func fetchStopMonitoring(for stopId: String) async throws -> FoliArrivalResponse {
        let url = try makeEndpointURL(path: "/sm/\(stopId)")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(FoliArrivalResponse.self, from: data)
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch real-time arrival monitoring data for a specific stop using numeric ID
    /// - Parameter stopId: The numeric ID of the stop to query
    /// - Returns: Stop monitoring response with arrival/departure information
    func fetchStopMonitoring(for stopId: Int) async throws -> FoliArrivalResponse {
        return try await fetchStopMonitoring(for: String(stopId))
    }
    
    /// Fetch arrivals only for a specific stop
    /// - Parameter stopId: The ID of the stop to monitor
    /// - Returns: Array of vehicle arrivals
    func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        let response = try await fetchStopMonitoring(for: stopId)
        guard response.isValid else {
            throw Foli.APIError.serverError(response.status)
        }
        return response.result
    }
    
    /// Fetch arrivals only for a specific stop using numeric ID
    /// - Parameter stopId: The numeric ID of the stop to monitor
    /// - Returns: Array of vehicle arrivals
    func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await fetchArrivals(for: String(stopId))
    }
}

