//
//  FoliClient+Trips.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Trips

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch all GTFS trips
    /// - Returns: Array of Trip objects
    func fetchTrips() async throws -> [Foli.Trip] {
        let url = try makeEndpointURL(path: "/gtfs/trips")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode([Foli.Trip].self, from: data)
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
}
