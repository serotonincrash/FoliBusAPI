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
    func clearCache(for type: Foli.Resource) async throws {
        try await cache?.clearCache(for: type)
    }
    
    /// Returns whether the cache currently has usable data for the given resource.
    ///
    /// This method returns `true` when the cache entry is still fresh, or when the
    /// cache can serve stale data because revalidation failed transiently.
    func hasValidCache(for type: Foli.Resource) async -> Bool {
        guard let cache = cache else { return false }
        return await cache.hasValidCache(for: type)
    }
    
    /// Get the age of cached data in seconds
    func cacheAge(for type: Foli.Resource) async -> TimeInterval? {
        await cache?.cacheAge(for: type)
    }
    
    /// Get the dataset ID being used for cached data
    /// - Parameter type: The specific resource type to check, or nil to get the most recently cached dataset ID
    /// - Returns: The dataset ID, or nil if no cached data exists
    func currentDatasetId(for type: Foli.Resource? = nil) async throws -> String? {
        guard let cache = cache else { return nil }
        return try await cache.currentDatasetId(for: type)
    }
    
    /// Revalidate a cached GTFS resource against the latest dataset metadata.
    @discardableResult
    func revalidateCache(for type: Foli.Resource) async throws -> Bool {
        guard let cache = cache else { return false }
        return try await cache.revalidateCache(for: type)
    }

    /// Starts a best-effort stale-while-revalidate refresh and removes its bookkeeping entry once the task finishes.
    internal func refreshCacheInBackground<T: Sendable>(for type: Foli.Resource, fetch: @escaping @Sendable () async throws -> T, save: @escaping @Sendable (T) async throws -> Void) async {
        await refreshTracker.cancelTask(for: type)

        let task = Task { [weak self] in
            guard let self else { return }
            await self.runBackgroundRefresh(for: type, fetch: fetch, save: save)
        }

        await refreshTracker.setTask(task, for: type)
    }

    /// Resolves a cacheable GTFS resource according to the client's configured ``Foli.CacheBehavior``,
    /// centralizing the cached-or-fetch / stale-while-revalidate / force-refresh / cached-only / no-cache
    /// policy across all data-retrieval call sites.
    ///
    /// - Parameters:
    ///   - resource: The cache resource key used for background refresh bookkeeping.
    ///   - load: Loads a fresh cached value, or nil if absent/expired.
    ///   - loadStale: Loads a stale cached value regardless of freshness, or nil if absent.
    ///   - save: Persists a freshly fetched value to the cache.
    ///   - fetch: Fetches the value from the network.
    ///   - rebuildIndex: Optional callback to rebuild in-memory lookup indexes from the value.
    /// - Returns: The resolved value according to `cacheBehavior`.
    internal func resolveCached<T: Sendable>(
        for resource: Foli.Resource,
        load: @escaping @Sendable () async throws -> T?,
        loadStale: @escaping @Sendable () async throws -> T?,
        save: @escaping @Sendable (T) async throws -> Void,
        fetch: @escaping @Sendable () async throws -> T,
        rebuildIndex: (@Sendable (T) async -> Void)? = nil
    ) async throws -> T {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await load() {
                if let rebuildIndex { await rebuildIndex(cached) }
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await loadStale() {
                if let rebuildIndex { await rebuildIndex(staleCached) }
                await refreshCacheInBackground(
                    for: resource,
                    fetch: fetch,
                    save: save
                )
                return staleCached
            }
            fallthrough

        case .forceRefresh:
            let fresh = try await fetch()
            if let rebuildIndex { await rebuildIndex(fresh) }
            try? await save(fresh)
            return fresh

        case .cachedOnly:
            guard let cached = try await load() else {
                throw Foli.CacheError.cacheMiss(resource)
            }
            if let rebuildIndex { await rebuildIndex(cached) }
            return cached

        case .noCache:
            let fresh = try await fetch()
            if let rebuildIndex { await rebuildIndex(fresh) }
            return fresh
        }
    }

    private func runBackgroundRefresh<T: Sendable>(for type: Foli.Resource, fetch: @escaping @Sendable () async throws -> T, save: @escaping @Sendable (T) async throws -> Void) async {
        // Get the current task reference for proper cleanup
        let currentTask = await refreshTracker.currentTask(for: type)

        defer {
            // Only clear if this is still the registered task (prevents clearing a newer task)
            if let currentTask {
                Task { [weak self] in
                    await self?.refreshTracker.clearTask(for: type, matching: currentTask)
                }
            }
        }

        do {
            let cacheStillCurrent = try await revalidateCache(for: type)
            guard !cacheStillCurrent else { return }
            let freshValue = try await fetch()
            try await save(freshValue)
        } catch is CancellationError {
            // Task was cancelled - this is expected lifecycle behavior, not an error
        } catch {
            notifyBackgroundRefreshError(type, error: error)
        }
    }

    /// Forwards a background-refresh error to the registered ``onBackgroundRefreshError`` handler.
    private func notifyBackgroundRefreshError(_ type: Foli.Resource, error: Error) {
        onBackgroundRefreshError?(type, error)
    }
}
