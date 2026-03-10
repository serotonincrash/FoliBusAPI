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
            let stopList = try await requestGTFS("/stops", as: FoliStopList.self)
            return stopList.stops
        }
    }
    
    /// Fetch a specific stop by its ID via GTFS API
    /// - Parameter stopId: The ID of the stop to fetch
    /// - Returns: The stop if found
    func fetchStop(for stopId: String) async throws -> Foli.Stop? {
        let stops = try await fetchStops()
        return stops.first { $0.id == stopId }
    }
    
    // MARK: - Stops with Caching
    
    /// Fetch stops with optional caching control
    /// - Parameter cacheBehavior: Cache behavior (default: .cachedOrFetch)
    /// - Returns: Array of Stop objects
    func fetchStops() async throws -> [Foli.Stop] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStops() {
                return cached
            }
            // fallthrough to fetch
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleStops() {
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
