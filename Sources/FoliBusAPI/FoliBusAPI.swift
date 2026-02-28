import Foundation

/// Main module entry point for the FoliBusAPI package
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public final class FoliBusAPI {
    
    /// Shared singleton instance of the API client
    public static let client = FoliClient.shared
    
    /// Initialize a new FoliBusAPI instance
    public init() {}
    
    // MARK: - Convenience Methods - Stops
    
    /// Fetch stop monitoring data for a stop
    /// - Parameter stopId: The stop ID to monitor
    /// - Returns: Array of vehicle arrivals
    public static func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
    /// Fetch stop monitoring data for a stop
    /// - Parameter stopId: The stop ID to monitor
    /// - Returns: Array of vehicle arrivals
    public static func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
    /// Fetch stop monitoring data for a stop
    /// - Parameter stop: The stop to monitor
    /// - Returns: Array of vehicle arrivals
    public static func fetchArrivals(for stop: Foli.Stop) async throws -> [Foli.Arrival] {
        return try await client.fetchArrivals(for: stop.id)
    }
    
    /// Fetch the complete list of stops
    /// - Returns: Array of all stops
    public static func fetchStops() async throws -> [Foli.Stop] {
        return try await client.fetchStops()
    }
    
    // MARK: - Convenience Methods - Routes (GTFS)
    
    /// Fetch the complete list of all routes from GTFS
    /// - Returns: Array of all routes
    public static func fetchRoutes() async throws -> [Foli.Route] {
        return try await client.fetchRoutes()
    }
    
    /// Fetch a specific route by its ID
    /// - Parameter routeId: The ID of the route to fetch
    /// - Returns: The route if found
    public static func fetchRoute(byId routeId: String) async throws -> Foli.Route? {
        return try await client.fetchRoute(forRoute: routeId)
    }
    
    /// Fetch routes that match a given line reference (e.g., "15")
    /// - Parameter lineRef: The line reference to search for
    /// - Returns: Array of matching routes
    public static func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        return try await client.fetchRoutes(for: lineRef)
    }
    
    /// Fetch routes of a specific type
    /// - Parameter routeType: The GTFS route type (0=Tram, 3=Bus, etc.)
    /// - Returns: Array of routes matching the type
    public static func fetchRoutes(ofType routeType: Int) async throws -> [Foli.Route] {
        let allRoutes = try await client.fetchRoutes()
        return allRoutes.filter { $0.routeType == routeType }
    }
    
    /// Fetch only bus routes
    /// - Returns: Array of bus routes
    public static func fetchBusRoutes() async throws -> [Foli.Route] {
        return try await fetchRoutes(ofType: 3)
    }
    
    /// Fetch only tram routes
    /// - Returns: Array of tram routes
    public static func fetchTramRoutes() async throws -> [Foli.Route] {
        return try await fetchRoutes(ofType: 0)
    }
}

