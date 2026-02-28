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
    public func fetchStopTimesFromNetwork() async throws -> [Foli.StopTime] {
        let url = try makeEndpointURL(path: "/gtfs/stop_times")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode([Foli.StopTime].self, from: data)
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    
    /// Fetch GTFS stop times for a specific trip ID
    /// - Parameter tripId: The ID of the trip
    /// - Returns: Array of StopTime objects associated with the trip
    public func fetchStopTimesFromNetwork(forTrip tripId: String) async throws -> [Foli.StopTime] {
        // Assuming endpoint structure /gtfs/stop_times/{tripId} based on API documentation
        let url = try makeEndpointURL(path: "/gtfs/stop_times/\(tripId)")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode([Foli.StopTime].self, from: data)
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch GTFS stop times for a specific stop ID
    /// - Parameter stopId: The ID of the stop
    /// - Returns: Array of StopTime objects associated with the stop
    public func fetchStopTimesFromNetwork(forStop stopId: String) async throws -> [Foli.StopTime] {
        // Assuming endpoint structure /gtfs/stop_times/{stopId} or similar dedicated endpoint
        let url = try makeEndpointURL(path: "/gtfs/stop_times/\(stopId)")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode([Foli.StopTime].self, from: data)
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    // MARK: - Stop Times with Caching
    
    /// Fetch all stop times with optional caching control
    /// - Parameter cacheBehavior: Cache behavior (default: .cachedOrFetch)
    /// - Returns: Array of StopTime objects
    func fetchStopTimes() async throws -> [Foli.StopTime] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStopTimes() {
                return cached
            }
            fallthrough
            
        case .forceRefresh:
            let stopTimes = try await fetchStopTimes()
            try? await cache?.saveStopTimes(stopTimes)
            return stopTimes
            
        case .cachedOnly:
            guard let cached = try await cache?.loadStopTimes() else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchStopTimes()
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
            return try await fetchStopTimes(forTrip: tripId)
        }
    }
    
    /// Fetch stop times for a stop with optional caching control
    /// - Parameters:
    ///   - stopId: The ID of the stop
    ///   - cacheBehavior: Cache behavior (default: .cachedOrFetch)
    /// - Returns: Array of StopTime objects associated with the stop
    func fetchStopTimes(forStopId stopId: String) async throws -> [Foli.StopTime] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadStopTimes(forStop: stopId) {
                return cached
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
