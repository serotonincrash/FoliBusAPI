//
//  FoliService+GeoJSON.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation
import FoliBusAPI

// MARK: - GeoJSON API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch available GeoJSON map layers.
    ///
    /// - Returns: Array of available map layers with metadata.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchGeoJSONLayers() async throws -> [Foli.GeoJSONLayer] {
        return try await client.fetchGeoJSONLayers()
    }
    
    /// Fetch all points of interest.
    ///
    /// - Returns: GeoJSON feature collection of all POIs.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchPointsOfInterest() async throws -> Foli.FeatureCollection {
        return try await client.fetchPointsOfInterest()
    }
    
    /// Fetch points of interest by category.
    ///
    /// - Parameter category: Category name.
    /// - Returns: GeoJSON feature collection of POIs in the category.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchPointsOfInterest(category: String) async throws -> Foli.FeatureCollection {
        return try await client.fetchPointsOfInterest(category: category)
    }
    
    /// Fetch Föli service area boundaries.
    ///
    /// - Parameters:
    ///   - resolution: Boundary resolution.
    ///   - format: Output format.
    /// - Returns: GeoJSON feature collection with boundary geometry.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchServiceBounds(resolution: FoliClient.BoundsResolution = .normal, format: FoliClient.BoundsFormat = .multiPolygon) async throws -> Foli.FeatureCollection {
        return try await client.fetchServiceBounds(resolution: resolution, format: format)
    }
}
