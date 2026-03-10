import Foundation
import SwiftUI

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

/// Main client for interacting with the Foli public transport API
///
/// To configure client behavior for SwiftUI, inject a configured provider via the environment
/// at your app's root, or pass a client explicitly to views that need it.
///
/// ## Environment Setup
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(
///                     \.foliClientProvider,
///                     DefaultFoliClientProvider(
///                         configuration: FoliClientConfiguration(cacheBehavior: .forceRefresh)
///                     )
///                 )
///         }
///     }
/// }
/// ```
///
/// ## Direct Usage
/// ```swift
/// struct MyView: View {
///     let client: FoliClient = .configured(cacheBehavior: .forceRefresh)
///     @FoliService(client: client) var foliService
/// }
/// ```
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public actor FoliClient {
    
    /// Base URL for the Foli API
    private let baseURL = "https://data.foli.fi/siri"
    
    /// Base URL for the Foli GTFS API
    private let gtfsBaseURL = "https://data.foli.fi/gtfs"
    
    /// URLSession for making network requests
    internal let session: URLSession
    
    /// Cache for GTFS data (optional - set to enable caching)
    internal var cache: (any Foli.Cache)?
    
    /// Whether this client should cache its static GTFS data
    internal var cacheBehavior: Foli.CacheBehavior = .cachedOrFetch
    
    /// Shared decoder for API responses.
    private let decoder = JSONDecoder()

    /// Custom initializer for dependency injection (useful for testing)
    public init(session: URLSession = .shared, cachedBy cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, withTimeout timeout: Foli.CacheTimeout = .default) {
        self.session = session
        self.cacheBehavior = cacheBehavior
        
        do {
            self.cache = try Foli.DiskCache(timeout: timeout)
        } catch {
            print("An error occured initialising the cache for FoliAPI.")
            self.cacheBehavior = .noCache
        }
    }
    
    // MARK: - Helper Methods
    
    /// Constructs a full URL for a given SIRI endpoint path
    /// - Parameter path: The endpoint path (e.g., "/sm" or "/sm/4")
    /// - Returns: A complete URL
    internal func makeEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }
    
    /// Constructs a full URL for a given GTFS endpoint path
    /// - Parameter path: The endpoint path (e.g., "/routes" or "/stops")
    /// - Returns: A complete URL
    internal func makeGTFSEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: gtfsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Fetch and decode a response from a SIRI endpoint.
    internal func requestSIRI<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeEndpointURL(path: path)
        return try await request(url, as: type)
    }

    /// Fetch and decode a response from a GTFS endpoint.
    internal func requestGTFS<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeGTFSEndpointURL(path: path)
        return try await request(url, as: type)
    }

    private func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw Foli.APIError.invalidResponse
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw Foli.APIError.decodingError(error)
            }
        } catch let error as Foli.APIError {
            throw error
        } catch {
            throw Foli.APIError.networkError(error)
        }
    }
}

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
            session: session,
            cachedBy: cacheBehavior,
            withTimeout: cacheTimeout
        )
    }
}

// MARK: - SwiftUI Environment Support

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EnvironmentValues {

    /// The provider used by `FoliService` to resolve a `FoliClient`.
    /// Set this at your app's root to control caching behavior while preserving a reusable client instance:
    /// ```swift
    /// RootView().environment(
    ///     \.foliClientProvider,
    ///     DefaultFoliClientProvider(
    ///         configuration: FoliClientConfiguration(cacheBehavior: .forceRefresh)
    ///     )
    /// )
    /// ```
    public var foliClientProvider: any FoliClientProviding {
        get { self[FoliClientProviderKey.self] }
        set { self[FoliClientProviderKey.self] = newValue }
    }

    private struct FoliClientProviderKey: EnvironmentKey {
        static let defaultValue: any FoliClientProviding = DefaultFoliClientProvider()
    }
}
