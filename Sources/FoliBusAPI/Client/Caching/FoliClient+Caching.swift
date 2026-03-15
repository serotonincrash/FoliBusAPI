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
    
    /// Get the dataset ID being used for cached data
    /// - Parameter type: The specific resource type to check, or nil to get the most recently cached dataset ID
    /// - Returns: The dataset ID, or nil if no cached data exists
    func currentDatasetId(for type: Foli.CacheResource? = nil) async throws -> String? {
        guard let cache = cache else { return nil }
        return try await cache.currentDatasetId(for: type)
    }
    
    /// Revalidate a cached GTFS resource against the latest dataset metadata.
    @discardableResult
    func revalidateCache(for type: Foli.CacheResource) async throws -> Bool {
        guard let cache = cache else { return false }
        return try await cache.revalidateCache(for: type)
    }

    internal func persistToCache(
        resource: Foli.CacheResource,
        saveOperation: @escaping @Sendable () async throws -> Void
    ) async {
        do {
            try await saveOperation()
        } catch {
            reportNonFatalCacheError(
                "Failed to persist cached resource \(String(describing: resource))",
                error: error
            )
        }
    }

    internal func reportNonFatalCacheError(_ message: String, error: Error) {
        logHandler?("\(message): \(error.localizedDescription)")
    }

    internal func refreshCacheInBackground<T>(for type: Foli.CacheResource, fetch: @escaping @Sendable () async throws -> T, save: @escaping @Sendable (T) async throws -> Void) {
        Task {
            do {
                let cacheStillCurrent = try await self.revalidateCache(for: type)
                guard !cacheStillCurrent else { return }
                let freshValue = try await fetch()
                try await save(freshValue)
            } catch {
                self.reportNonFatalCacheError(
                    "Background cache refresh failed for \(String(describing: type))",
                    error: error
                )
            }
        }
    }
}
