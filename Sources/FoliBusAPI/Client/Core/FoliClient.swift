import Foundation

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
/// ## SwiftUI usage through the environment
/// ```swift
/// struct MyView: View {
///     @FoliService var foliService
///
///     // rest of the view...
/// }
/// ```
///
/// ## SwiftUI usage with an explicit client
/// ```swift
/// struct MyView: View {
///     let client: FoliClient = .configured(cacheBehavior: .forceRefresh)
///     @FoliService(client: client) var foliService
///
///     // rest of the view...
/// }
/// ```
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public actor FoliClient {
    /// Base URL for the Foli API
    internal let baseURL = "https://data.foli.fi/siri"

    /// Base URL for the Foli GTFS API
    internal let gtfsBaseURL = "https://data.foli.fi/gtfs"

    /// Transport used for making network requests
    internal let transport: any FoliTransport

    /// Cache for GTFS data (optional - set to enable caching)
    internal var cache: (any Foli.Cache)?

    /// Whether this client should cache its static GTFS data
    internal var cacheBehavior: Foli.CacheBehavior = .cachedOrFetch

    /// Shared decoder for API responses.
    internal let decoder = JSONDecoder()
    internal var inFlightRequests: [RequestKey: AnyInFlightTask] = [:]
    internal var stopsByID: [String: Foli.Stop] = [:]
    internal var routesByID: [String: Foli.Route] = [:]
    internal var routesByShortName: [String: [Foli.Route]] = [:]

    /// Creates a client that executes requests through a `URLSession`.
    /// - Parameters:
    ///   - session: The session used for network requests.
    ///   - cacheBehavior: The cache behavior to apply to cacheable GTFS resources.
    ///   - timeout: The disk-cache freshness policy.
    public init(session: URLSession = .shared, cachedBy cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, withTimeout timeout: Foli.CacheTimeout = .default) {
        self.transport = URLSessionTransport(session: session)
        self.cacheBehavior = cacheBehavior

        do {
            self.cache = try Foli.DiskCache(timeout: timeout)
        } catch {
            print("An error occurred initialising the cache for FoliAPI. Defaulting to no cache implementation.")
            self.cacheBehavior = .noCache
        }
    }

    /// Creates a client that executes requests through a custom transport.
    ///
    /// This initializer is especially useful for testing, offline fixtures, or advanced
    /// networking setups where request execution should be controlled independently from
    /// the client’s decoding and cache logic.
    /// - Parameters:
    ///   - transport: The transport used to execute requests.
    ///   - cacheBehavior: The cache behavior to apply to cacheable GTFS resources.
    ///   - timeout: The disk-cache freshness policy.
    public init(transport: any FoliTransport, cachedBy cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, withTimeout timeout: Foli.CacheTimeout = .default) {
        self.transport = transport
        self.cacheBehavior = cacheBehavior

        do {
            self.cache = try Foli.DiskCache(timeout: timeout)
        } catch {
            print("An error occured initialising the cache for FoliAPI.")
            self.cacheBehavior = .noCache
        }
    }
}
