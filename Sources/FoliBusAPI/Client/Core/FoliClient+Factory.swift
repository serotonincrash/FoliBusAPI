import Foundation

// MARK: - Convenience Factory

extension FoliClient {
    /// Creates a configured client backed by a `URLSession` transport.
    /// - Parameters:
    ///   - cacheBehavior: The cache behavior to use for cacheable GTFS resources.
    ///   - cacheTTL: The freshness policy applied by the disk cache.
    ///   - session: The session whose configuration should be used for request execution.
    /// - Returns: A configured ``FoliClient`` instance.
    public static func makeConfigured(
        cacheBehavior: Foli.CacheBehavior = .cachedOrFetch,
        cacheTTL: Foli.CacheTTL = .default,
        session: URLSession = .shared
    ) throws -> FoliClient {
        try FoliClient(
            transport: URLSessionTransport(session: session),
            cacheBehavior: cacheBehavior,
            cacheTTL: cacheTTL
        )
    }
}
