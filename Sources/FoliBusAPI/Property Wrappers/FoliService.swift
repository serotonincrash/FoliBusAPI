import SwiftUI

// MARK: - FoliService Property Wrapper

/// A property wrapper that provides a service interface for fetching Foli transit data
/// with async methods for manual state management.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliService: DynamicProperty, Sendable {
    
    private let client: FoliClient
    
    public init(client: FoliClient = .shared) {
        self.client = client
    }
    
    public var wrappedValue: FoliService {
        self
    }
}

// MARK: - Routes API

public extension FoliService {
    
    /// Fetch all routes from the API
    /// - Returns: Array of all routes
    func fetchRoutes() async throws -> [Foli.Route] {
        return try await client.fetchRoutes()
    }
    
    /// Fetch a specific route by ID
    /// - Parameter routeId: The route ID to fetch
    /// - Returns: The route if found
    func fetchRoute(id routeId: String) async throws -> Foli.Route {
        guard let route = try await client.fetchRoute(byId: routeId) else {
            throw Foli.APIError.noData
        }
        return route
    }
    
    func fetchRoute(id routeId: Int) async throws -> Foli.Route {
        return try await fetchRoute(id: String(routeId))
    }
    
    /// Fetch routes matching a specific line reference
    /// - Parameter lineRef: The line reference (e.g., "15")
    /// - Returns: Array of matching routes
    func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        return try await client.fetchRoutes(byLineRef: lineRef)
    }
    
}

// MARK: - Stops API

public extension FoliService {
    
    /// Fetch all stops from the API
    /// - Returns: Array of all stops
    func fetchStops() async throws -> [Foli.Stop] {
        return try await client.fetchStops()
    }
    
    /// Fetch a specific stop by ID
    /// - Parameter stopId: The stop ID to fetch
    /// - Returns: The stop if found
    func fetchStop(id stopId: String) async throws -> Foli.Stop {
        guard let stop = try await client.fetchStop(byId: stopId) else {
            throw Foli.APIError.noData
        }
        return stop
    }
    
    func fetchStop(id stopId: Int) async throws -> Foli.Stop {
        return try await fetchStop(id: String(stopId))
    }
    
    // MARK: - Convenience Methods
    
    /// Sort stops by name
    func sortedStops(_ stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.sorted { $0.stopName < $1.stopName }
    }
    
    /// Sort stops by ID
    func sortedStopsById(_ stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.sorted { $0.id < $1.id }
    }
    
    /// Search stops by name or ID
    func searchStops(query: String, in stops: [Foli.Stop]) -> [Foli.Stop] {
        stops.filter { stop in
            stop.stopName.localizedCaseInsensitiveContains(query) || stop.id.contains(query)
        }.sorted { $0.stopName < $1.stopName }
    }
}

// MARK: - Arrivals API

public extension FoliService {
    
    /// Fetch arrivals for a specific stop
    /// - Parameter stopId: The stop ID
    /// - Returns: Array of arrivals for the stop
    func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
    func fetchArrivals(for stopId: Int) async throws -> [Foli.Arrival] {
        return try await fetchArrivals(for: String(stopId))
    }
    
}

