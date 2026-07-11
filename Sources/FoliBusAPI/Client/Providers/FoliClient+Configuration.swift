import Foundation

/// Configuration used to construct a ``FoliClient`` instance.
///
/// Use this type when providing clients through SwiftUI environment integration
/// or when you want to centralize cache and transport-related defaults.
public struct FoliClientConfiguration: Sendable {
    /// The cache strategy used for cacheable GTFS resources.
    public let cacheBehavior: Foli.CacheBehavior
    /// The freshness policy used by the disk cache.
    public let cacheTTL: Foli.CacheTTL
    /// The session used by the default transport when constructing clients from this configuration.
    public let session: URLSession

    /// Creates a client configuration.
    /// - Parameters:
    ///   - cacheBehavior: The cache strategy used for GTFS-backed resources.
    ///   - cacheTTL: The freshness policy used by the disk cache.
    ///   - session: The session used for request execution.
    public init(
        cacheBehavior: Foli.CacheBehavior = .cachedOrFetch,
        cacheTTL: Foli.CacheTTL = .default,
        session: URLSession = .shared
    ) {
        self.cacheBehavior = cacheBehavior
        self.cacheTTL = cacheTTL
        self.session = session
    }

    /// The default client configuration.
    public static let `default` = FoliClientConfiguration()
}

/// A type that can vend configured ``FoliClient`` instances.
public protocol FoliClientProviding: Sendable {
    /// Returns a client instance suitable for the current environment.
    func client() -> FoliClient
}

/// Default provider that constructs and reuses a single configured client instance.
public final class DefaultFoliClientProvider: FoliClientProviding {
    private let sharedClient: FoliClient

    /// Creates a provider backed by the supplied configuration.
    ///
    /// This initializer cannot throw (it backs the SwiftUI environment default), so if
    /// constructing a client with the supplied configuration fails (e.g. disk-cache
    /// initialization failure), it falls back to a client with `cacheBehavior: .noCache`.
    /// That fallback construction provably cannot throw: `FoliClient.init` only throws
    /// when it attempts disk-cache initialization, which it skips entirely for `.noCache`.
    /// - Parameter configuration: The configuration used when the shared client is created.
    public init(configuration: FoliClientConfiguration = .default) {
        let client = try? FoliClient(
            session: configuration.session,
            cacheBehavior: configuration.cacheBehavior,
            cacheTTL: configuration.cacheTTL
        )
        // swiftlint:disable:next force_try
        self.sharedClient = client ?? (try! FoliClient(cacheBehavior: .noCache))
    }

    /// Returns the shared client instance.
    public func client() -> FoliClient {
        sharedClient
    }
}