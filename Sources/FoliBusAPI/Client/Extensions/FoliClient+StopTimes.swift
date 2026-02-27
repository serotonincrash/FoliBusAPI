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
    /// - Returns: Array of StopTime objects
    func fetchStopTimes() async throws -> [Foli.StopTime] {
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
    func fetchStopTimes(forTripId tripId: String) async throws -> [Foli.StopTime] {
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
    
    /// Fetch GTFS stop times for a specific trip ID using numeric ID
    /// - Parameter tripId: The numeric ID of the trip
    /// - Returns: Array of StopTime objects associated with the trip
    func fetchStopTimes(forTripId tripId: Int) async throws -> [Foli.StopTime] {
        return try await fetchStopTimes(forTripId: String(tripId))
    }
    
    /// Fetch GTFS stop times for a specific stop ID
    /// - Parameter stopId: The ID of the stop
    /// - Returns: Array of StopTime objects associated with the stop
    func fetchStopTimes(forStopId stopId: String) async throws -> [Foli.StopTime] {
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
    
    /// Fetch GTFS stop times for a specific stop ID using numeric ID
    /// - Parameter stopId: The numeric ID of the stop
    /// - Returns: Array of StopTime objects associated with the stop
    func fetchStopTimes(forStopId stopId: Int) async throws -> [Foli.StopTime] {
        return try await fetchStopTimes(forStopId: String(stopId))
    }
}
