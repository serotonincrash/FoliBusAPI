import Foundation

// MARK: - Convenience Factory

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    /// Creates a configured client backed by a `URLSession` transport.
    /// - Parameters:
    ///   - cacheBehavior: The cache behavior to use for cacheable GTFS resources.
    ///   - cacheTimeout: The freshness policy applied by the disk cache.
    ///   - session: The session whose configuration should be used for request execution.
    /// - Returns: A configured ``FoliClient`` instance.
    public static func configured(
        cacheBehavior: Foli.CacheBehavior = .cachedOrFetch,
        cacheTimeout: Foli.CacheTimeout = .default,
        session: URLSession = .shared
    ) -> FoliClient {
        FoliClient(
            transport: URLSessionTransport(session: session),
            cachedBy: cacheBehavior,
            withTimeout: cacheTimeout
        )
    }
}
