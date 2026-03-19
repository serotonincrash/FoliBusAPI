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
    
    /// Returns whether the cache currently has usable data for the given resource.
    ///
    /// This method returns `true` when the cache entry is still fresh, or when the
    /// cache can serve stale data because revalidation failed transiently.
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

    /// Starts a best-effort stale-while-revalidate refresh and removes its bookkeeping entry once the task finishes.
    internal func refreshCacheInBackground<T>(for type: Foli.CacheResource, fetch: @escaping @Sendable () async throws -> T, save: @escaping @Sendable (T) async throws -> Void) {
        cancelBackgroundRefreshTask(for: type)

        let task = Task { [weak self] in
            guard let self else { return }
            await self.runBackgroundRefresh(for: type, fetch: fetch, save: save)
        }

        setBackgroundRefreshTask(task, for: type)
    }

    private func runBackgroundRefresh<T>(for type: Foli.CacheResource, fetch: @escaping @Sendable () async throws -> T, save: @escaping @Sendable (T) async throws -> Void) async {
        defer {
            backgroundRefreshTasks[type] = nil
        }

        do {
            let cacheStillCurrent = try await revalidateCache(for: type)
            guard !cacheStillCurrent else { return }
            let freshValue = try await fetch()
            try await save(freshValue)
        } catch {
            notifyBackgroundRefreshError(type, error: error)
        }
    }

    /// Forwards a background-refresh error to the registered ``onBackgroundRefreshError`` handler.
    private func notifyBackgroundRefreshError(_ type: Foli.CacheResource, error: Error) {
        onBackgroundRefreshError?(type, error)
    }
}
