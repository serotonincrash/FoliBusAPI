import Foundation

/// Configuration used to construct a ``FoliClient`` instance.
///
/// Use this type when providing clients through SwiftUI environment integration
/// or when you want to centralize cache and transport-related defaults.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliClientConfiguration: Sendable {
    /// The cache strategy used for cacheable GTFS resources.
    public let cacheBehavior: Foli.CacheBehavior
    /// The freshness policy used by the disk cache.
    public let cacheTimeout: Foli.CacheTimeout
    /// The session used by the default transport when constructing clients from this configuration.
    public let session: URLSession

    /// Creates a client configuration.
    /// - Parameters:
    ///   - cacheBehavior: The cache strategy used for GTFS-backed resources.
    ///   - cacheTimeout: The freshness policy used by the disk cache.
    ///   - session: The session used for request execution.
    public init(
        cacheBehavior: Foli.CacheBehavior = .cachedOrFetch,
        cacheTimeout: Foli.CacheTimeout = .default,
        session: URLSession = .shared
    ) {
        self.cacheBehavior = cacheBehavior
        self.cacheTimeout = cacheTimeout
        self.session = session
    }

    /// The default client configuration.
    public static let `default` = FoliClientConfiguration()
}

/// A type that can vend configured ``FoliClient`` instances.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public protocol FoliClientProviding: Sendable {
    /// Returns a client instance suitable for the current environment.
    func client() -> FoliClient
}

/// Default provider that constructs and reuses a single configured client instance.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public final class DefaultFoliClientProvider: FoliClientProviding {
    private let sharedClient: FoliClient

    /// Creates a provider backed by the supplied configuration.
    /// - Parameter configuration: The configuration used when the shared client is created.
    public init(configuration: FoliClientConfiguration = .default) {
        self.sharedClient = FoliClient(
            session: configuration.session,
            cachedBy: configuration.cacheBehavior,
            withTimeout: configuration.cacheTimeout
        )
    }

    /// Returns the shared client instance.
    public func client() -> FoliClient {
        sharedClient
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension DefaultFoliClientProvider {
    /// Shared default provider used by convenience entry points.
    public static let shared = DefaultFoliClientProvider()
}
