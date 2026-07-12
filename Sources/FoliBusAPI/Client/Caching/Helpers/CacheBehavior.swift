//
//  CacheBehavior.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

// MARK: - Cache Behavior
public extension Foli {
    /// Controls how ``FoliClient`` uses cached GTFS resources.
    ///
    /// Cache behavior determines the balance between data freshness and network efficiency.
    /// Different behaviors are appropriate for different use cases.
    ///
    /// ## Behavior Comparison
    /// | Behavior | Reads Cache | Writes Cache | Network Call |
    /// |----------|-------------|--------------|--------------|
    /// | ``cachedOrFetch`` | ✓ (if valid) | ✓ | Only if needed |
    /// | ``staleWhileRevalidate`` | ✓ (even stale) | ✓ | Background |
    /// | ``forceRefresh`` | ✗ | ✓ | Always |
    /// | ``cachedOnly`` | ✓ (even stale) | ✗ | Never |
    /// | ``noCache`` | ✗ | ✗ | Always |
    ///
    /// ## Example
    /// ```swift
    /// // Default behavior - use cache when available
    /// let client = try FoliClient(cacheBehavior: .cachedOrFetch)
    ///
    /// // Show stale data immediately, refresh in background
    /// let client = try FoliClient(cacheBehavior: .staleWhileRevalidate)
    ///
    /// // Always fetch fresh data
    /// let client = try FoliClient(cacheBehavior: .forceRefresh)
    /// ```
    enum CacheBehavior: Sendable {
        /// Use cached data if available and still validated as current; otherwise fetch from the network.
        ///
        /// This is the default behavior and provides a good balance between freshness and efficiency.
        /// A miss here — no cached entry, an expired entry whose revalidation
        /// definitively confirmed the dataset changed — always triggers a synchronous
        /// fetch from the network before returning, so the caller never receives data
        /// known to be out of date. If revalidation is merely inconclusive (a
        /// transient network error), the stale entry is served instead, matching
        /// ``hasValidCache(for:)``.
        case cachedOrFetch

        /// Return stale cached data immediately and refresh it in the background.
        ///
        /// Ideal for UI that needs to display data quickly while ensuring eventual consistency.
        /// The background refresh error can be observed via ``FoliClient/onBackgroundRefreshError``.
        case staleWhileRevalidate
        
        /// Always fetch from the network and refresh the cache with the new value.
        ///
        /// Use when data freshness is critical, such as after user-initiated refresh actions.
        case forceRefresh
        
        /// Use only cached data — served regardless of freshness — and fail with
        /// ``Foli/CacheError`` if nothing is cached.
        ///
        /// Never makes a network call. Useful for offline-first scenarios where
        /// stale data beats no data.
        case cachedOnly
        
        /// Fetch from the network without reading or writing cache entries.
        ///
        /// Bypasses the cache entirely. Useful for debugging or when caching is inappropriate.
        case noCache
    }
}
