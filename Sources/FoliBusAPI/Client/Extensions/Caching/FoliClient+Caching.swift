//
//  FoliClient+Caching.swift
//  FoliBusAPI
//
//  Created for GTFS data caching
//

import Foundation

// MARK: - Caching

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    // MARK: - Cache Management
    
    /// Clear all cached GTFS data
    func clearCache() async throws {
        try await cache?.clearAllCache()
    }
    
    /// Clear cached data for a specific type
    func clearCache(for type: Foli.CacheResource) async throws {
        try await cache?.clearCache(for: type)
    }
    
    /// Check if cached data exists and is valid
    func hasValidCache(for type: Foli.CacheResource) async -> Bool {
        guard let cache = cache else { return false }
        return await cache.hasValidCache(for: type)
    }
    
    /// Get the age of cached data in seconds
    func cacheAge(for type: Foli.CacheResource) async -> TimeInterval? {
        await cache?.cacheAge(for: type)
    }
}
