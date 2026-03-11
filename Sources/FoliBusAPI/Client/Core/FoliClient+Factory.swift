import Foundation

// MARK: - Convenience Factory

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    /// Creates a configured FoliClient with custom cache settings
    /// - Parameters:
    ///   - cacheBehavior: The cache behavior to use
    ///   - cacheTimeout: The cache timeout duration
    ///   - session: Optional custom URLSession
    /// - Returns: A configured FoliClient instance
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
