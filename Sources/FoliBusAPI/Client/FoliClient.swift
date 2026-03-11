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
    internal let baseURL = "https://data.foli.fi/siri"

    /// Base URL for the Foli GTFS API
    internal let gtfsBaseURL = "https://data.foli.fi/gtfs"

    /// URLSession for making network requests
    internal let session: URLSession

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
}
