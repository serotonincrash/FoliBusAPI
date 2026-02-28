import Foundation

/// Main client for interacting with the Foli public transport API
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public actor FoliClient {
    
    /// Shared singleton instance
    public static let shared = FoliClient()
    
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
    public init(session: URLSession = .shared, cachedBy cacheBehavior: Foli.CacheBehavior = .cachedOrFetch) {
        self.session = session
        self.cacheBehavior = cacheBehavior
        
        do {
            self.cache = try Foli.DiskCache()
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
