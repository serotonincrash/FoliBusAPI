//
//  FoliClient+Trips.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

// MARK: - Trips

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch all GTFS trips
    /// - Returns: Array of Trip objects
    func fetchTripsFromNetwork() async throws -> [Foli.Trip] {
        try await performDeduplicated(.trips) { [self] in
            try await requestGTFS("/trips/all", as: [Foli.Trip].self)
        }
    }
    
    /// Fetch GTFS trips for a specific route
    /// - Parameter routeId: The ID of the route to fetch trips for
    /// - Returns: Array of Trip objects belonging to the specified route
    func fetchTripsFromNetwork(forRoute routeId: String) async throws -> [Foli.Trip] {
        try await performDeduplicated(.tripsForRoute(routeId)) { [self] in
            try await requestGTFS("/trips/route/\(routeId)", as: [Foli.Trip].self)
        }
    }

    /// Fetch GTFS trip metadata for a specific trip ID
    /// - Parameter tripId: The ID of the trip to fetch
    /// - Returns: The trip if found
    func fetchTrip(tripId: String) async throws -> Foli.Trip? {
        let trips = try await requestGTFS("/trips/trip/\(tripId)", as: [Foli.Trip].self)
        return trips.first
    }
    
    // MARK: - Trips with Caching
    
    /// Fetch all trips using the client's configured caching behavior.
    /// - Returns: Array of Trip objects.
    func fetchTrips() async throws -> [Foli.Trip] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadTrips() {
                return cached
            }
            // fallthrough to fetch
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleTrips() {
                refreshCacheInBackground(
                    for: .trips,
                    fetch: { [self] in try await fetchTripsFromNetwork() },
                    save: { [cache] trips in try await cache?.saveTrips(trips) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let trips = try await fetchTripsFromNetwork()
            try? await cache?.saveTrips(trips)
            return trips
            
        case .cachedOnly:
            guard let cached = try await cache?.loadTrips() else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchTripsFromNetwork()
        }
    }
    
    /// Fetch trips for a specific route using the client's configured caching behavior.
    /// - Parameter routeId: The ID of the route to fetch trips for.
    /// - Returns: Array of Trip objects belonging to the specified route.
    func fetchTrips(forRoute routeId: String) async throws -> [Foli.Trip] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadTrips(forRoute: routeId) {
                return cached
            }
            // fallthrough to fetch
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleTrips(forRoute: routeId) {
                refreshCacheInBackground(
                    for: .tripsForRoute(routeId),
                    fetch: { [self] in try await fetchTripsFromNetwork(forRoute: routeId) },
                    save: { [cache] trips in try await cache?.saveTrips(trips, forRoute: routeId) }
                )
                return staleCached
            }
            fallthrough
            
        case .forceRefresh:
            let trips = try await fetchTripsFromNetwork(forRoute: routeId)
            try? await cache?.saveTrips(trips, forRoute: routeId)
            return trips
            
        case .cachedOnly:
            guard let cached = try await cache?.loadTrips(forRoute: routeId) else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchTripsFromNetwork(forRoute: routeId)
        }
    }
}
