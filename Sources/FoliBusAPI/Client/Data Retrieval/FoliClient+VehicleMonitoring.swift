//
//  FoliClient+VehicleMonitoring.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation

// MARK: - Vehicle Monitoring

public extension FoliClient {
    
    /// Fetch all current vehicle locations from the SIRI Vehicle Monitoring (VM) endpoint.
    ///
    /// This method retrieves real-time location and status information for all active vehicles
    /// in the Föli transit system.
    ///
    /// - Returns: Array of vehicle locations.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    ///
    /// - Note: The VM endpoint returns a large response (high bandwidth usage).
    ///         Recommended minimum polling interval is 3 seconds.
    ///         Vehicle locations are estimates based on GPS, odometer, and schedule data.
    ///
    /// - SeeAlso: ``fetchVehicleLocations(for:)`` for filtering by line reference.
    func fetchVehicleLocations() async throws -> [Foli.VehicleLocation] {
        let response = try await fetchVehicleMonitoring()
        guard response.isValid else {
            throw Foli.APIError.serverError(response.status)
        }
        return response.vehicles
    }
    
    /// Fetch vehicle locations filtered by line reference.
    ///
    /// - Parameter lineRef: The line reference to filter by (e.g., "14", "2A").
    /// - Returns: Array of vehicle locations for the specified line.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    ///
    /// - Note: This method fetches all vehicles and filters client-side. For better performance
    ///         when tracking multiple lines, consider calling ``fetchVehicleLocations()`` once
    ///         and filtering the results yourself.
    func fetchVehicleLocations(for lineRef: String) async throws -> [Foli.VehicleLocation] {
        let vehicles = try await fetchVehicleLocations()
        return vehicles.filter { $0.lineRef == lineRef }
    }
    
    /// Fetch vehicle locations for multiple line references.
    ///
    /// - Parameter lineRefs: Array of line references to filter by.
    /// - Returns: Array of vehicle locations matching any of the specified lines.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    func fetchVehicleLocations(for lineRefs: [String]) async throws -> [Foli.VehicleLocation] {
        let vehicles = try await fetchVehicleLocations()
        let lineRefSet = Set(lineRefs)
        return vehicles.filter { lineRefSet.contains($0.lineRef) }
    }
}

extension FoliClient {
    
    /// Fetch vehicle-monitoring data from the SIRI VM endpoint.
    ///
    /// - Returns: A vehicle-monitoring response containing all active vehicles.
    /// - Throws: `Foli.APIError` if the request fails.
    ///
    /// - Note: This is an internal method. Use ``fetchVehicleLocations()`` for the public API.
    ///         Request is deduplicated to prevent concurrent duplicate requests.
    internal func fetchVehicleMonitoring() async throws -> Foli.VehicleMonitoringResponse {
        try await dedup.performDeduplicated(forKey: .vehicleMonitoring) { [self] in
            try await requestSIRI("/vm", as: Foli.VehicleMonitoringResponse.self)
        }
    }
}
