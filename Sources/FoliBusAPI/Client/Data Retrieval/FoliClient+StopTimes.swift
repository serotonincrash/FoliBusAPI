//
//  FoliClient+StopTimes.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Stop Times

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch all GTFS stop times
    /// Not recommended for use, not data-efficient.
    /// - Returns: Array of StopTime objects
    internal func fetchStopTimesFromNetwork() async throws -> [Foli.StopTime] {
        try await dedup.performDeduplicated(.stopTimes) { [self] in
            try await requestGTFS("/stop_times", as: [Foli.StopTime].self)
        }
    }
    
    
    /// Fetch GTFS stop times for a specific trip ID
    /// - Parameter tripId: The ID of the trip
    /// - Returns: Array of StopTime objects associated with the trip
    internal func fetchStopTimesFromNetwork(forTrip tripId: String) async throws -> [Foli.StopTime] {
        // Documented endpoint: /gtfs/stop_times/trip/{tripId}
        try await dedup.performDeduplicated(.stopTimesForTrip(tripId)) { [self] in
            try await requestGTFS("/stop_times/trip/\(tripId)", as: [Foli.StopTime].self)
        }
    }
    
    /// Fetch GTFS stop times for a specific stop ID
    /// - Parameter stopId: The ID of the stop
    /// - Returns: Array of StopTime objects associated with the stop
    internal func fetchStopTimesFromNetwork(forStop stopId: String) async throws -> [Foli.StopTime] {
        // Documented endpoint: /gtfs/stop_times/stop/{stopId}
        try await dedup.performDeduplicated(.stopTimesForStop(stopId)) { [self] in
            try await requestGTFS("/stop_times/stop/\(stopId)", as: [Foli.StopTime].self)
        }
    }
    
    // MARK: - Stop Times with Caching
    
    /// Fetch all stop times using the client's configured caching behavior.
    /// - Returns: Array of StopTime objects.
    func fetchStopTimes() async throws -> [Foli.StopTime] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStopTimes() {
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleStopTimes() {
                await refreshCacheInBackground(
                    for: .stopTimes,
                    fetch: { [self] in try await fetchStopTimesFromNetwork() },
                    save: { [cache] stopTimes in try await cache?.saveStopTimes(stopTimes) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let stopTimes = try await fetchStopTimesFromNetwork()
            try? await cache?.saveStopTimes(stopTimes)
            return stopTimes
            
        case .cachedOnly:
            guard let cached = try await cache?.loadStopTimes() else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchStopTimesFromNetwork()
        }
    }
    
    /// Fetch stop times for a trip with optional caching control
    /// - Parameters:
    ///   - tripId: The ID of the trip
    /// - Returns: Array of StopTime objects associated with the trip
    func fetchStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStopTimes(forTrip: tripId) {
                return cached
            }
            // fallthrough to fetch
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleStopTimes(forTrip: tripId) {
                await refreshCacheInBackground(
                    for: .stopTimesForTrip(tripId),
                    fetch: { [self] in try await fetchStopTimesFromNetwork(forTrip: tripId) },
                    save: { [cache] stopTimes in try await cache?.saveStopTimes(stopTimes, forTrip: tripId) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let stopTimes = try await fetchStopTimesFromNetwork(forTrip: tripId)
            try? await cache?.saveStopTimes(stopTimes, forTrip: tripId)
            return stopTimes
            
        case .cachedOnly:
            guard let cached = try await cache?.loadStopTimes(forTrip: tripId) else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchStopTimesFromNetwork(forTrip: tripId)
        }
    }
    
    /// Fetch stop times for a stop using the client's configured caching behavior.
    /// - Parameter stopId: The ID of the stop.
    /// - Returns: Array of StopTime objects associated with the stop.
    func fetchStopTimes(forStop stopId: String) async throws -> [Foli.StopTime] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStopTimes(forStop: stopId) {
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleStopTimes(forStop: stopId) {
                await refreshCacheInBackground(
                    for: .stopTimesForStop(stopId),
                    fetch: { [self] in try await fetchStopTimesFromNetwork(forStop: stopId) },
                    save: { [cache] stopTimes in try await cache?.saveStopTimes(stopTimes, forStop: stopId) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let stopTimes = try await fetchStopTimesFromNetwork(forStop: stopId)
            try? await cache?.saveStopTimes(stopTimes, forStop: stopId)
            return stopTimes
            
        case .cachedOnly:
            guard let cached = try await cache?.loadStopTimes(forStop: stopId) else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchStopTimesFromNetwork(forStop: stopId)
        }
    }

}
