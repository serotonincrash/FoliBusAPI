//
//  FoliClient+GeoJSON.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation

// MARK: - GeoJSON

public extension FoliClient {
    
    /// Fetch available GeoJSON map layers.
    ///
    /// - Returns: Array of available map layers with metadata.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchGeoJSONLayers() async throws -> [Foli.GeoJSONLayer] {
        try await dedup.performDeduplicated(forKey: .resource(.geoJSONLayers)) { [self] in
            let response = try await requestGeoJSON("/geojson/layers", as: Foli.GeoJSONLayersResponse.self)
            return response.geojson.layers
        }
    }
    
    /// Fetch all points of interest.
    ///
    /// - Returns: GeoJSON feature collection of all POIs.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchPointsOfInterest() async throws -> Foli.FeatureCollection {
        try await dedup.performDeduplicated(forKey: .resource(.geoJSONPOI)) { [self] in
            try await requestGeoJSON("/geojson/poi", as: Foli.FeatureCollection.self)
        }
    }
    
    /// Fetch points of interest by category.
    ///
    /// - Parameter category: Category name (e.g., "service_points", "loading_points").
    /// - Returns: GeoJSON feature collection of POIs in the category.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchPointsOfInterest(inCategory category: String) async throws -> Foli.FeatureCollection {
        try await dedup.performDeduplicated(forKey: .resource(.geoJSONPOICategory(category))) { [self] in
            try await requestGeoJSON("/geojson/poi/\(FoliRequester.pathComponent(category))", as: Foli.FeatureCollection.self)
        }
    }
    
    /// Fetch Föli service area boundaries.
    ///
    /// - Parameters:
    ///   - resolution: Boundary resolution (strict/normal/compact).
    ///   - format: Output format (multipolygon/multilinestring).
    /// - Returns: GeoJSON feature collection with boundary geometry.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchServiceBounds(resolution: BoundsResolution = .normal, format: BoundsFormat = .multiPolygon) async throws -> Foli.FeatureCollection {
        let resolutionKey = switch resolution {
        case .strict: "strict"
        case .compact: "compact"
        case .normal: "normal"
        }
        let formatKey = format == .multiLineString ? "ml" : "mp"
        
        return try await dedup.performDeduplicated(forKey: .resource(.geoJSONBounds(resolution: resolutionKey, format: formatKey))) { [self] in
            var path = "/geojson/bounds"

            if resolution != .normal {
                path += "/\(resolutionKey)"
            }
            
            if format == .multiLineString {
                path += "/ml"
            }
            
            return try await requestGeoJSON(path, as: Foli.FeatureCollection.self)
        }
    }
    
    /// Boundary resolution options
    enum BoundsResolution: Sendable {
        /// Precise municipal boundaries (~90KB, 4500 points)
        case strict
        /// Balanced resolution (~20KB, 900 points)
        case normal
        /// Mobile-friendly (~8KB, 400 points)
        case compact
    }
    
    /// Boundary format options
    enum BoundsFormat: Sendable {
        /// Polygon geometry
        case multiPolygon
        /// Line geometry
        case multiLineString
    }
}
