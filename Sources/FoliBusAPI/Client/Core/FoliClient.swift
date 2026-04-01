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

    /// Base URL for the Foli Alerts API
    internal let alertsBaseURL = "https://data.foli.fi"

    /// Base URL for the Foli GeoJSON API
    internal let geoJSONBaseURL = "https://data.foli.fi"

    /// Transport used for making network requests
    internal let transport: any FoliTransport

    /// Cache for GTFS data (optional - set to enable caching)
    internal var cache: (any Foli.Cache)?

    /// Whether this client should cache its static GTFS data
    internal var cacheBehavior: Foli.CacheBehavior = .cachedOrFetch

    /// Shared decoder for API responses.
    internal let decoder = JSONDecoder()
    internal var inFlightRequests: [Foli.Resource: AnyInFlightTask] = [:]
    internal var stopsByID: [String: Foli.Stop] = [:]
    internal var routesByID: [String: Foli.Route] = [:]
    internal var routesByShortName: [String: [Foli.Route]] = [:]
    internal var agenciesByID: [String: Foli.Agency] = [:]
    internal var calendarsByID: [String: Foli.Calendar] = [:]
    internal var tripsByID: [String: Foli.Trip] = [:]

    /// Tracks background revalidation tasks so they can be cancelled when the client
    /// is asked to refresh the same resource again before the previous refresh completes.
    internal var backgroundRefreshTasks: [Foli.Resource: Task<Void, Never>] = [:]

    /// Called when a background stale-while-revalidate refresh fails.
    ///
    /// The client itself cannot surface errors from background refreshes (they are
    /// fire-and-observe), so set this handler if you want to log or react to failures.
    /// The handler is called on the actor's executor.
    ///
    /// ```swift
    /// client.onBackgroundRefreshError = { resource, error in
    ///     logger.error("Background refresh failed for \(resource): \(error)")
    /// }
    /// ```
    public var onBackgroundRefreshError: (@Sendable (Foli.Resource, Error) -> Void)?

    /// Creates a client that executes requests through a `URLSession`.
    /// - Parameters:
    ///   - session: The session used for network requests.
    ///   - cacheBehavior: The cache behavior to apply to cacheable GTFS resources.
    ///   - cacheTimeout: The disk-cache freshness policy.
    public init(session: URLSession = .shared, cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, cacheTimeout: Foli.CacheTimeout = .default) {
        self.transport = URLSessionTransport(session: session)
        self.cacheBehavior = cacheBehavior

        do {
            self.cache = try Foli.DiskCache(timeout: cacheTimeout)
        } catch {
            // Cache initialization failed - fall back to no-cache mode
            // This is expected when disk access is unavailable
            self.cacheBehavior = .noCache
        }
    }

    /// Creates a client that executes requests through a custom transport.
    ///
    /// This initializer is especially useful for testing, offline fixtures, or advanced
    /// networking setups where request execution should be controlled independently from
    /// the client's decoding and cache logic.
    /// - Parameters:
    ///   - transport: The transport used to execute requests.
    ///   - cacheBehavior: The cache behavior to apply to cacheable GTFS resources.
    ///   - cacheTimeout: The disk-cache freshness policy.
    public init(transport: any FoliTransport, cacheBehavior: Foli.CacheBehavior = .cachedOrFetch, cacheTimeout: Foli.CacheTimeout = .default) {
        self.transport = transport
        self.cacheBehavior = cacheBehavior

        do {
            self.cache = try Foli.DiskCache(timeout: cacheTimeout)
        } catch {
            // Cache initialization failed - fall back to no-cache mode
            // This is expected when disk access is unavailable
            self.cacheBehavior = .noCache
        }
    }

    /// Records a background refresh task for the provided resource.
    internal func setBackgroundRefreshTask(_ task: Task<Void, Never>, for resource: Foli.Resource) {
        backgroundRefreshTasks[resource] = task
    }

    /// Removes a background refresh task if it is still the task currently registered for the resource.
    internal func clearBackgroundRefreshTask(for resource: Foli.Resource, matching task: Task<Void, Never>) {
        guard let currentTask = backgroundRefreshTasks[resource], currentTask == task else {
            return
        }
        backgroundRefreshTasks[resource] = nil
    }

    /// Cancels any in-flight background refresh for the provided resource.
    internal func cancelBackgroundRefreshTask(for resource: Foli.Resource) {
        backgroundRefreshTasks[resource]?.cancel()
    }

    /// Returns whether a resource currently has a background refresh task registered.
    internal func hasBackgroundRefreshTask(for resource: Foli.Resource) -> Bool {
        backgroundRefreshTasks[resource] != nil
    }
}
