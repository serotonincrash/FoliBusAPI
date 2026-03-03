//
//  FoliService+StopTimes.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Stop Times API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all stop times from the GTFS API
    /// - Returns: Array of all stop times
    func fetchStopTimes() async throws -> [Foli.StopTime] {
        return try await client.fetchStopTimes()
    }
    
    /// Fetch stop times for a specific trip
    /// - Parameter tripId: The trip ID to fetch stop times for
    /// - Returns: Array of stop times for the trip
    func fetchStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime] {
        return try await client.fetchStopTimes(forTrip: tripId)
    }
    
    /// Fetch stop times for a specific stop
    /// - Parameter stopId: The stop ID to fetch stop times for
    /// - Returns: Array of stop times for the stop
    func fetchStopTimes(forStopId stopId: String) async throws -> [Foli.StopTime] {
        return try await client.fetchStopTimes(forStopId: stopId)
    }
}
