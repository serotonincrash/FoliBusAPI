//
//  FoliClient+Stops.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Stop List (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch the complete list of all known stops via GTFS API
    /// - Returns: An array of all stops
    func fetchStops() async throws -> [Foli.Stop] {
        let url = try makeGTFSEndpointURL(path: "/stops")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            let stopList = try JSONDecoder().decode(FoliStopList.self, from: data)
            return stopList.stops
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch a specific stop by its ID via GTFS API
    /// - Parameter stopId: The ID of the stop to fetch
    /// - Returns: The stop if found
    func fetchStop(byId stopId: String) async throws -> Foli.Stop? {
        let stops = try await fetchStops()
        return stops.first { $0.id == stopId }
    }
}
