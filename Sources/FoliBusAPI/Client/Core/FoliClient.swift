import Foundation

/// Main client for interacting with the Foli public transport API.
///
/// `FoliClient` is an actor that coordinates request execution, caching, in-flight
/// deduplication, and in-memory lookup indexes. It delegates the concrete work to
/// dedicated extracted types:
///
/// - ``requester`` (``FoliRequester``) owns transport, JSON decoding, and URL construction.
/// - ``dedup`` (``FoliDedup``) coalesces concurrent identical requests.
/// - ``indexes`` (``FoliIndexes``) maintains O(1) entity lookup dictionaries.
/// - ``refreshTracker`` (``FoliRefreshTracker``) tracks background stale-while-revalidate tasks.
///
/// ## Direct usage
/// ```swift
/// let client = FoliClient(
///     cacheBehavior: .forceRefresh,
///     cacheTimeout: .default
/// )
/// let routes = try await client.fetchRoutes()
/// ```
///
/// ## Convenience facade
/// For simple one-off access without managing a client instance, use the ``FoliBusAPI``
/// static facade, which routes through a configurable provider:
/// ```swift
/// let routes = try await FoliBusAPI.fetchRoutes()
/// ```
///
/// ## SwiftUI integration
/// SwiftUI integration (the `@FoliService` property wrapper and environment provider)
/// lives in the separate `FoliBusUI` target. See that target's documentation for details.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public actor FoliClient {
    /// Transport, decoder, base URLs, and request execution.
    ///
    /// Extracted into a separate ``Sendable`` value type so that JSON decoding
    /// for large GTFS payloads does not block the actor's executor.
    internal let requester: FoliRequester

    /// Cache for GTFS data (optional - set to enable caching)
    internal var cache: (any Foli.Cache)?

    /// Whether this client should cache its static GTFS data
    internal var cacheBehavior: Foli.CacheBehavior = .cachedOrFetch

    internal let indexes = FoliIndexes()

    /// Deduplicates concurrent in-flight requests for the same resource.
    internal let dedup = FoliDedup()

    /// Tracks background stale-while-revalidate refresh tasks.
    internal let refreshTracker = FoliRefreshTracker()

    /// Called when a background stale-while-revalidate refresh fails.
    ///
    /// The client itself cannot surface errors from background refreshes (they are
    /// fire-and-observe), so set this handler if you want to log or react to failures.
    /// The handler is called on the actor's executor.
    ///
    /// ```swift
    /// client.onBackgroundRefreshError = { resource, error in
    ///     logger.error("Background refresh failed for \(resource): \(error)")
    /// }
    /// ```
    public var onBackgroundRefreshError: (@Sendable (Foli.Resource, Error) -> Void)?

    /// Creates a client that executes requests through a `URLSession`.
    /// - Parameters:
    ///   - session: The session used for network requests.
    ///   - cacheBehavior: The cache behavior to apply to cacheable GTFS resources.
    ///   - cacheTimeout: The disk-cache freshness policy.
    public init(session: URLSession = .shared, cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, cacheTimeout: Foli.CacheTimeout = .default) {
        self.requester = FoliRequester(transport: URLSessionTransport(session: session))
        self.cacheBehavior = cacheBehavior

        do {
            self.cache = try Foli.DiskCache(timeout: cacheTimeout)
        } catch {
            // Cache initialization failed - fall back to no-cache mode
            // This is expected when disk access is unavailable
            self.cacheBehavior = .noCache
        }
    }

    /// Creates a client that executes requests through a custom transport.
    ///
    /// This initializer is especially useful for testing, offline fixtures, or advanced
    /// networking setups where request execution should be controlled independently from
    /// the client's decoding and cache logic.
    /// - Parameters:
    ///   - transport: The transport used to execute requests.
    ///   - cacheBehavior: The cache behavior to apply to cacheable GTFS resources.
    ///   - cacheTimeout: The disk-cache freshness policy.
    public init(transport: any FoliTransport, cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, cacheTimeout: Foli.CacheTimeout = .default) {
        self.requester = FoliRequester(transport: transport)
        self.cacheBehavior = cacheBehavior

        do {
            self.cache = try Foli.DiskCache(timeout: cacheTimeout)
        } catch {
            // Cache initialization failed - fall back to no-cache mode
            // This is expected when disk access is unavailable
            self.cacheBehavior = .noCache
        }
    }

}
