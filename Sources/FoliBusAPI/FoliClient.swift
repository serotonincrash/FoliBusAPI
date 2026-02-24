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
    private let session: URLSession
    
    /// Custom initializer for dependency injection (useful for testing)
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Stop List (GTFS)
    
    /// Fetch the complete list of all known stops via GTFS API
    /// - Returns: An array of all stops
    public func fetchStops() async throws -> [Foli.Stop] {
        let url = try makeGTFSEndpointURL(path: "/stops")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            let stopList = try JSONDecoder().decode(FoliStopList.self, from: data)
            return stopList.stops
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch a specific stop by its ID via GTFS API
    /// - Parameter stopId: The ID of the stop to fetch
    /// - Returns: The stop if found
    public func fetchStop(byId stopId: String) async throws -> Foli.Stop? {
        let stops = try await fetchStops()
        return stops.first { $0.id == stopId }
    }
    
    // MARK: - Routes (GTFS)
    
    /// Fetch the complete list of all known routes from GTFS
    /// - Returns: An array of all routes
    public func fetchRoutes() async throws -> [Foli.Route] {
        let url = try makeGTFSEndpointURL(path: "/routes")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            let routeList = try JSONDecoder().decode(FoliRouteList.self, from: data)
            return routeList.routes
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch a specific route by its ID
    /// - Parameter routeId: The ID of route to fetch
    /// - Returns: The route if found
    public func fetchRoute(byId routeId: String) async throws -> Foli.Route? {
        let routes = try await fetchRoutes()
        return routes.first { $0.id == routeId }
    }
    
    /// Fetch routes that match a given line reference (e.g., "15")
    /// - Parameter lineRef: The line reference to search for
    /// - Returns: Array of matching routes
    public func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        let routes = try await fetchRoutes()
        return routes.filter { $0.shortName == lineRef }
    }
    
    // MARK: - Arrivals
    
    /// Fetch real-time arrival data for a specific stop
    /// - Parameter stopId: The ID of the stop to query
    /// - Returns: Stop monitoring response with arrival/departure information
    public func fetchStopMonitoring(for stopId: String) async throws -> FoliArrivalResponse {
        let url = try makeEndpointURL(path: "/sm/\(stopId)")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(FoliArrivalResponse.self, from: data)
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    /// Fetch real-time arrival monitoring data for a specific stop using numeric ID
    /// - Parameter stopId: The numeric ID of the stop to query
    /// - Returns: Stop monitoring response with arrival/departure information
    public func fetchStopMonitoring(for stopId: Int) async throws -> FoliArrivalResponse {
        return try await fetchStopMonitoring(for: String(stopId))
    }
    
    /// Fetch arrivals only for a specific stop
    /// - Parameter stopId: The ID of the stop to monitor
    /// - Returns: Array of vehicle arrivals
    public func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        let response = try await fetchStopMonitoring(for: stopId)
        guard response.isValid else {
            throw Foli.APIError.serverError(response.status)
        }
        return response.result
    }
    
    /// Fetch arrivals only for a specific stop using numeric ID
    /// - Parameter stopId: The numeric ID of the stop to monitor
    /// - Returns: Array of vehicle arrivals
    public func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await fetchArrivals(for: String(stopId))
    }
    
    // MARK: - Helper Methods
    
    /// Constructs a full URL for a given SIRI endpoint path
    /// - Parameter path: The endpoint path (e.g., "/sm" or "/sm/4")
    /// - Returns: A complete URL
    private func makeEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }
    
    /// Constructs a full URL for a given GTFS endpoint path
    /// - Parameter path: The endpoint path (e.g., "/routes" or "/stops")
    /// - Returns: A complete URL
    private func makeGTFSEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: gtfsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }
}
