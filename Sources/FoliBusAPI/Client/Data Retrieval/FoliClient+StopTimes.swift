//
//  FoliClient+StopTimes.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Stop Times

public extension FoliClient {
    
    /// Fetch all GTFS stop times
    /// Not recommended for use, not data-efficient.
    /// - Returns: Array of StopTime objects
    internal func fetchStopTimesFromNetwork() async throws -> [Foli.StopTime] {
        try await dedup.performDeduplicated(forKey: .resource(.stopTimes)) { [self] in
            try await requestGTFS("/stop_times", as: [Foli.StopTime].self)
        }
    }
    
    
    /// Fetch GTFS stop times for a specific trip ID
    /// - Parameter tripId: The ID of the trip
    /// - Returns: Array of StopTime objects associated with the trip
    internal func fetchStopTimesFromNetwork(forTrip tripId: String) async throws -> [Foli.StopTime] {
        // Documented endpoint: /gtfs/stop_times/trip/{tripId}
        try await dedup.performDeduplicated(forKey: .resource(.stopTimesForTrip(tripId))) { [self] in
            try await requestGTFS("/stop_times/trip/\(FoliRequester.pathComponent(tripId))", as: [Foli.StopTime].self)
        }
    }
    
    /// Fetch GTFS stop times for a specific stop ID
    /// - Parameter stopId: The ID of the stop
    /// - Returns: Array of StopTime objects associated with the stop
    internal func fetchStopTimesFromNetwork(forStop stopId: String) async throws -> [Foli.StopTime] {
        // Documented endpoint: /gtfs/stop_times/stop/{stopId}
        try await dedup.performDeduplicated(forKey: .resource(.stopTimesForStop(stopId))) { [self] in
            try await requestGTFS("/stop_times/stop/\(FoliRequester.pathComponent(stopId))", as: [Foli.StopTime].self)
        }
    }
    
    // MARK: - Stop Times with Caching
    
    /// Fetch all stop times using the client's configured caching behavior.
    /// - Returns: Array of StopTime objects.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchStopTimes() async throws -> [Foli.StopTime] {
        try await resolveCached(
            for: .stopTimes,
            load: { [cache] in try await cache?.loadStopTimes() },
            loadStale: { [cache] in try await cache?.loadStaleStopTimes() },
            save: { [cache] stopTimes, datasetId in try await cache?.saveStopTimes(stopTimes, datasetId: datasetId) },
            fetch: { [self] in try await fetchStopTimesFromNetwork() }
        )
    }
    
    /// Fetch stop times for a trip with optional caching control
    /// - Parameters:
    ///   - tripId: The ID of the trip
    /// - Returns: Array of StopTime objects associated with the trip
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime] {
        try await resolveCached(
            for: .stopTimesForTrip(tripId),
            load: { [cache] in try await cache?.loadStopTimes(forTrip: tripId) },
            loadStale: { [cache] in try await cache?.loadStaleStopTimes(forTrip: tripId) },
            save: { [cache] stopTimes, datasetId in try await cache?.saveStopTimes(stopTimes, forTrip: tripId, datasetId: datasetId) },
            fetch: { [self] in try await fetchStopTimesFromNetwork(forTrip: tripId) }
        )
    }
    
    /// Fetch stop times for a stop using the client's configured caching behavior.
    /// - Parameter stopId: The ID of the stop.
    /// - Returns: Array of StopTime objects associated with the stop.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchStopTimes(forStop stopId: String) async throws -> [Foli.StopTime] {
        try await resolveCached(
            for: .stopTimesForStop(stopId),
            load: { [cache] in try await cache?.loadStopTimes(forStop: stopId) },
            loadStale: { [cache] in try await cache?.loadStaleStopTimes(forStop: stopId) },
            save: { [cache] stopTimes, datasetId in try await cache?.saveStopTimes(stopTimes, forStop: stopId, datasetId: datasetId) },
            fetch: { [self] in try await fetchStopTimesFromNetwork(forStop: stopId) }
        )
    }

}
