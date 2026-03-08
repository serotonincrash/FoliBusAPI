import Foundation
import SwiftUI

/// Main client for interacting with the Foli public transport API
///
/// To configure caching behavior, inject a configured client via SwiftUI environment
/// at your app's root, or pass it explicitly to views that need it.
///
/// ## Environment Setup
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: any Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(\.foliClient, .configured(cacheBehavior: .forceRefresh))
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
    
    /// The FoliClient instance to use for FoliService
    /// Set this at your app's root to configure caching behavior:
    /// ```swift
    /// RootView().environment(\.foliClient, .configured(cacheBehavior: .forceRefresh))
    /// ```
    public var foliClient: FoliClient? {
        get { self[FoliClientKey.self] }
        set { self[FoliClientKey.self] = newValue }
    }
    
    private struct FoliClientKey: EnvironmentKey {
        static let defaultValue: FoliClient? = nil
    }
}

