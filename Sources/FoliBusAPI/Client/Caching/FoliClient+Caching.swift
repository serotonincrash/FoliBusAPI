//
//  FoliClient+Caching.swift
//  FoliBusAPI
//
//  Created for GTFS data caching
//

import Foundation

// MARK: - Caching

/// Holds a reference to a background refresh task so the task body can reference itself.
///
/// ``@unchecked Sendable`` is safe here because:
/// 1. `ref.task = task` runs synchronously on the `FoliClient` actor *before* the
///    `Task {}` closure begins executing, because `Task {}` inherits the actor's
///    isolation and cannot start until the actor yields.
/// 2. The closure reads `ref.task` only after the assignment has completed.
///
/// **Do not** change the `Task {}` to `Task.detached` or move this code to a
/// `nonisolated` context — that would break the ordering guarantee and introduce
/// a data race.
private final class TaskReference: @unchecked Sendable {
    var task: Task<Void, Never>?
}

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

    /// Starts a best-effort stale-while-revalidate refresh unless one is already in flight
    /// for the resource, and removes its bookkeeping entry once the task finishes.
    internal func refreshCacheInBackground<T: Sendable>(for type: Foli.Resource, fetch: @escaping @Sendable () async throws -> T, save: @escaping @Sendable (T, String?) async throws -> Void) async {
        let (registration, registrationContinuation) = AsyncStream.makeStream(of: Bool.self)

        let ref = TaskReference()
        let task = Task { [weak self, ref] in
            // Do no work until the registration outcome is known, so the task can neither
            // race an already-in-flight refresh nor finish before it is registered
            // (which would strand a dead entry in the tracker).
            var isRegistered = false
            for await outcome in registration {
                isRegistered = outcome
                break
            }
            guard isRegistered, let self, let task = ref.task else { return }
            await self.runBackgroundRefresh(for: type, task: task, fetch: fetch, save: save)
        }
        ref.task = task

        let registered = await refreshTracker.setTaskIfAbsent(task, for: type)
        registrationContinuation.yield(registered)
        registrationContinuation.finish()
    }

    /// Resolves a cacheable GTFS resource according to the client's configured ``Foli.CacheBehavior``,
    /// centralizing the cached-or-fetch / stale-while-revalidate / force-refresh / cached-only / no-cache
    /// policy across all data-retrieval call sites.
    ///
    /// - Parameters:
    ///   - resource: The cache resource key used for background refresh bookkeeping.
    ///   - load: Loads a fresh cached value, or nil if absent/expired.
    ///   - loadStale: Loads a stale cached value regardless of freshness, or nil if absent.
    ///   - save: Persists a freshly fetched value to the cache, tagged with the
    ///     dataset ID captured immediately before the fetch that produced it (or `nil`
    ///     if that capture failed, in which case the cache falls back to its own
    ///     `datasetIdFetcher`).
    ///   - fetch: Fetches the value from the network.
    ///   - rebuildIndex: Optional callback to rebuild in-memory lookup indexes from the value.
    /// - Returns: The resolved value according to `cacheBehavior`.
    internal func resolveCached<T: Sendable>(
        for resource: Foli.Resource,
        load: @escaping @Sendable () async throws -> T?,
        loadStale: @escaping @Sendable () async throws -> T?,
        save: @escaping @Sendable (T, String?) async throws -> Void,
        fetch: @escaping @Sendable () async throws -> T,
        rebuildIndex: (@Sendable (T) async -> Void)? = nil
    ) async throws -> T {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await load() {
                if let rebuildIndex { await rebuildIndex(cached) }
                return cached
            }
            // No fallthrough into `.staleWhileRevalidate`: a cache miss here (nil from
            // `load()`) means either there's nothing cached, or `loadResource`'s own
            // revalidation already determined the cached entry is stale/gone. Either
            // way `.cachedOrFetch` fetches fresh synchronously rather than serving
            // possibly-stale data from a background refresh.
            let datasetId = try? await cache?.fetchLatestDatasetId()
            let fresh = try await fetch()
            if let rebuildIndex { await rebuildIndex(fresh) }
            try? await save(fresh, datasetId)
            return fresh

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
            let datasetId = try? await cache?.fetchLatestDatasetId()
            let fresh = try await fetch()
            if let rebuildIndex { await rebuildIndex(fresh) }
            try? await save(fresh, datasetId)
            return fresh

        case .cachedOnly:
            // Serve whatever is on disk regardless of freshness: `.cachedOnly` promises
            // no network access, and load() revalidates expired entries over the network.
            guard let cached = try await loadStale() else {
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

    private func runBackgroundRefresh<T: Sendable>(
        for type: Foli.Resource,
        task: Task<Void, Never>,
        fetch: @escaping @Sendable () async throws -> T,
        save: @escaping @Sendable (T, String?) async throws -> Void
    ) async {
        do {
            let cacheStillCurrent = try await revalidateCache(for: type)
            guard !cacheStillCurrent else {
                await refreshTracker.clearTask(for: type, matching: task)
                return
            }
            try Task.checkCancellation()
            // Captured before `fetch()` so a mid-fetch dataset flip fails safe: the
            // saved entry gets tagged with the pre-fetch ID, which the next
            // revalidation will detect as stale and refetch (never stuck serving
            // stale-forever).
            let datasetId = try? await cache?.fetchLatestDatasetId()
            let freshValue = try await fetch()
            try Task.checkCancellation()
            try await save(freshValue, datasetId)
            await refreshTracker.clearTask(for: type, matching: task)
        } catch is CancellationError {
            await refreshTracker.clearTask(for: type, matching: task)
        } catch {
            await refreshTracker.clearTask(for: type, matching: task)
            notifyBackgroundRefreshError(type, error: error)
        }
    }

    /// Forwards a background-refresh error to the registered ``onBackgroundRefreshError`` handler.
    private func notifyBackgroundRefreshError(_ type: Foli.Resource, error: Error) {
        onBackgroundRefreshError?(type, error)
    }
}
