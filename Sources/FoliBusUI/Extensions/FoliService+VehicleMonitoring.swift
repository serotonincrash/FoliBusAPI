//
//  FoliService+VehicleMonitoring.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation
import FoliBusAPI

// MARK: - Vehicle Monitoring API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all current vehicle locations from the SIRI Vehicle Monitoring (VM) endpoint.
    ///
    /// - Returns: Array of vehicle locations.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    ///
    /// - Note: The VM endpoint returns a large response. Minimum polling interval: 3 seconds.
    func fetchVehicleLocations() async throws -> [Foli.VehicleLocation] {
        return try await client.fetchVehicleLocations()
    }
    
    /// Fetch vehicle locations filtered by line reference.
    ///
    /// - Parameter lineRef: The line reference to filter by (e.g., "14", "2A").
    /// - Returns: Array of vehicle locations for the specified line.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    func fetchVehicleLocations(for lineRef: String) async throws -> [Foli.VehicleLocation] {
        return try await client.fetchVehicleLocations(for: lineRef)
    }
    
    /// Fetch vehicle locations for multiple line references.
    ///
    /// - Parameter lineRefs: Array of line references to filter by.
    /// - Returns: Array of vehicle locations matching any of the specified lines.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    func fetchVehicleLocations(for lineRefs: [String]) async throws -> [Foli.VehicleLocation] {
        return try await client.fetchVehicleLocations(for: lineRefs)
    }
}
