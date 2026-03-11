import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliClientConfiguration: Sendable {
    public let cacheBehavior: Foli.CacheBehavior
    public let cacheTimeout: Foli.CacheTimeout
    public let session: URLSession

    public init(
        cacheBehavior: Foli.CacheBehavior = .cachedOrFetch,
        cacheTimeout: Foli.CacheTimeout = .default,
        session: URLSession = .shared
    ) {
        self.cacheBehavior = cacheBehavior
        self.cacheTimeout = cacheTimeout
        self.session = session
    }

    public static let `default` = FoliClientConfiguration()
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public protocol FoliClientProviding: Sendable {
    func client() -> FoliClient
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public final class DefaultFoliClientProvider: FoliClientProviding, @unchecked Sendable {
    private let configuration: FoliClientConfiguration
    private lazy var sharedClient: FoliClient = {
        FoliClient(
            session: configuration.session,
            cachedBy: configuration.cacheBehavior,
            withTimeout: configuration.cacheTimeout
        )
    }()

    public init(configuration: FoliClientConfiguration = .default) {
        self.configuration = configuration
    }

    public func client() -> FoliClient {
        sharedClient
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension DefaultFoliClientProvider {
    public static let shared = DefaultFoliClientProvider()
}
