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
    public func fetchStopsFromNetwork() async throws -> [Foli.Stop] {
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
    public func fetchStop(for stopId: String) async throws -> Foli.Stop? {
        let stops = try await fetchStops()
        return stops.first { $0.id == stopId }
    }
    
    // MARK: - Stops with Caching
    
    /// Fetch stops with optional caching control
    /// - Parameter cacheBehavior: Cache behavior (default: .cachedOrFetch)
    /// - Returns: Array of Stop objects
    public func fetchStops() async throws -> [Foli.Stop] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStops() {
                return cached
            }
            // fallthrough to fetch
            fallthrough
            
        case .forceRefresh:
            let stops = try await fetchStopsFromNetwork()
            try? await cache?.saveStops(stops)
            return stops
            
        case .cachedOnly:
            guard let cached = try await cache?.loadStops() else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchStopsFromNetwork()
        }
    }
    
}
