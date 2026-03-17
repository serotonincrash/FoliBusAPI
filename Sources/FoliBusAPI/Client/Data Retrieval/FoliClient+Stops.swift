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
    func fetchStopsFromNetwork() async throws -> [Foli.Stop] {
        try await performDeduplicated(.stops) { [self] in
            let stopList = try await requestGTFS("/stops", as: Foli.StopList.self)
            return stopList.stops
        }
    }
    
    /// Fetch a specific stop by its ID via GTFS API
    /// - Parameter stopId: The ID of the stop to fetch
    /// - Returns: The stop if found
    func fetchStop(for stopId: String) async throws -> Foli.Stop? {
        _ = try await fetchStops()
        return indexedStop(for: stopId)
    }
    
    // MARK: - Stops with Caching
    
    /// Fetch stops using the client's configured caching behavior.
    /// - Returns: Array of Stop objects.
    func fetchStops() async throws -> [Foli.Stop] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStops() {
                rebuildStopIndex(using: cached)
                return cached
            }
            // fallthrough to fetch
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleStops() {
                rebuildStopIndex(using: staleCached)
                refreshCacheInBackground(
                    for: .stops,
                    fetch: { [self] in try await fetchStopsFromNetwork() },
                    save: { [cache] stops in try await cache?.saveStops(stops) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let stops = try await fetchStopsFromNetwork()
            rebuildStopIndex(using: stops)
            try? await cache?.saveStops(stops)
            return stops
            
        case .cachedOnly:
            guard let cached = try await cache?.loadStops() else {
                throw Foli.APIError.noData
            }
            rebuildStopIndex(using: cached)
            return cached
            
        case .noCache:
            let stops = try await fetchStopsFromNetwork()
            rebuildStopIndex(using: stops)
            return stops
        }
    }
    
}
