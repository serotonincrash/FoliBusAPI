//
//  FoliClient+GeoJSON.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation

// MARK: - GeoJSON

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch available GeoJSON map layers.
    ///
    /// - Returns: Array of available map layers with metadata.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchGeoJSONLayers() async throws -> [Foli.GeoJSONLayer] {
        let response = try await requestGeoJSON("/geojson/layers", as: Foli.GeoJSONLayersResponse.self)
        return response.geojson.layers
    }
    
    /// Fetch all points of interest.
    ///
    /// - Returns: GeoJSON feature collection of all POIs.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchPointsOfInterest() async throws -> Foli.FeatureCollection {
        try await requestGeoJSON("/geojson/poi", as: Foli.FeatureCollection.self)
    }
    
    /// Fetch points of interest by category.
    ///
    /// - Parameter category: Category name (e.g., "service_points", "loading_points").
    /// - Returns: GeoJSON feature collection of POIs in the category.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchPointsOfInterest(category: String) async throws -> Foli.FeatureCollection {
        try await requestGeoJSON("/geojson/poi/\(category)", as: Foli.FeatureCollection.self)
    }
    
    /// Fetch Föli service area boundaries.
    ///
    /// - Parameters:
    ///   - resolution: Boundary resolution (strict/normal/compact).
    ///   - format: Output format (multipolygon/multilinestring).
    /// - Returns: GeoJSON feature collection with boundary geometry.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchServiceBounds(resolution: BoundsResolution = .normal, format: BoundsFormat = .multiPolygon) async throws -> Foli.FeatureCollection {
        var path = "/geojson/bounds"
        
        switch resolution {
        case .strict:
            path += "/strict"
        case .compact:
            path += "/compact"
        case .normal:
            break
        }
        
        if format == .multiLineString {
            path += "/ml"
        }
        
        return try await requestGeoJSON(path, as: Foli.FeatureCollection.self)
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

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    /// Fetch and decode a response from a GeoJSON endpoint.
    internal func requestGeoJSON<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let urlString = baseURL.replacingOccurrences(of: "/siri", with: "") + path
        guard let url = URL(string: urlString) else {
            throw Foli.APIError.invalidURL
        }
        
        do {
            let request = URLRequest(url: url)
            let (data, response) = try await transport.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw Foli.APIError.invalidResponse
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw Foli.APIError.decodingError(Foli.APIError.WrappedError(decodingError))
        } catch let apiError as Foli.APIError {
            throw apiError
        } catch {
            throw Foli.APIError.networkError(Foli.APIError.WrappedError(error))
        }
    }
}
