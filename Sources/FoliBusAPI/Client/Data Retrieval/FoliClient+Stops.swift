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
    internal func fetchStopsFromNetwork() async throws -> [Foli.Stop] {
        try await dedup.performDeduplicated(forKey: .resource(.stops)) { [self] in
            let stopList = try await requestGTFS("/stops", as: Foli.StopList.self)
            return stopList.stops
        }
    }
    
    /// Fetch a specific stop by its ID via GTFS API.
    ///
    /// The Foli API does not support individual stop lookups — this method fetches all stops
    /// (cached) and performs an O(1) dictionary lookup.
    /// The first call populates the cache; subsequent calls are instant.
    ///
    /// - Parameter stopId: The ID of the stop to fetch
    /// - Returns: The stop if found
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func stop(for stopId: String) async throws -> Foli.Stop? {
        _ = try await fetchStops()
        return await indexes.stop(for: stopId)
    }
    
    // MARK: - Stops with Caching
    
    /// Fetch stops using the client's configured caching behavior.
    /// - Returns: Array of Stop objects.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchStops() async throws -> [Foli.Stop] {
        try await resolveCached(
            for: .stops,
            load: { [cache] in try await cache?.loadStops() },
            loadStale: { [cache] in try await cache?.loadStaleStops() },
            save: { [cache] stops in try await cache?.saveStops(stops) },
            fetch: { [self] in try await fetchStopsFromNetwork() },
            rebuildIndex: { [self] stops in await indexes.rebuildStops(using: stops) }
        )
    }
    
}
