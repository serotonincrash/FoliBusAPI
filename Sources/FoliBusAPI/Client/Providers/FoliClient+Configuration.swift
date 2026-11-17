import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
    /// The directory used for disk-cache files, or `nil` for the default Application Support location.
    ///
    /// Supply this on platforms such as Android or Linux, where the app provides its own files directory.
    public let cacheDirectory: URL?

    /// Creates a client configuration.
    /// - Parameters:
    ///   - cacheBehavior: The cache strategy used for GTFS-backed resources.
    ///   - cacheTTL: The freshness policy used by the disk cache.
    ///   - session: The session used for request execution.
    ///   - cacheDirectory: The disk-cache directory, or `nil` for the default location.
    public init(
        cacheBehavior: Foli.CacheBehavior = .cachedOrFetch,
        cacheTTL: Foli.CacheTTL = .default,
        session: URLSession = .shared,
        cacheDirectory: URL? = nil
    ) {
        self.cacheBehavior = cacheBehavior
        self.cacheTTL = cacheTTL
        self.session = session
        self.cacheDirectory = cacheDirectory
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

    /// The error that prevented the configured disk cache from initializing, or `nil` if it initialized.
    ///
    /// When non-nil, the provider's client was created with `cacheBehavior: .noCache` instead.
    public let cacheInitializationError: (any Error)?

    /// Creates a provider backed by the supplied configuration.
    ///
    /// This initializer cannot throw (it backs the SwiftUI environment default), so if
    /// constructing a client with the supplied configuration fails (e.g. disk-cache
    /// initialization failure), it falls back to a client with `cacheBehavior: .noCache` and records the failure in
    /// ``cacheInitializationError``.
    /// That fallback construction provably cannot throw: `FoliClient.init` only throws
    /// when it attempts disk-cache initialization, which it skips entirely for `.noCache`.
    /// - Parameter configuration: The configuration used when the shared client is created.
    public init(configuration: FoliClientConfiguration = .default) {
        do {
            self.sharedClient = try FoliClient(
                session: configuration.session,
                cacheBehavior: configuration.cacheBehavior,
                cacheTTL: configuration.cacheTTL,
                cacheDirectory: configuration.cacheDirectory
            )
            self.cacheInitializationError = nil
        } catch {
            // swiftlint:disable:next force_try
            self.sharedClient = try! FoliClient(session: configuration.session, cacheBehavior: .noCache)
            self.cacheInitializationError = error
        }
    }

    /// Returns the shared client instance.
    public func client() -> FoliClient {
        sharedClient
    }
}