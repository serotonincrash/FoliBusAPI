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
    internal func fetchTripsFromNetwork() async throws -> [Foli.Trip] {
        try await dedup.performDeduplicated(.trips) { [self] in
            try await requestGTFS("/trips/all", as: [Foli.Trip].self)
        }
    }
    
    /// Fetch GTFS trips for a specific route
    /// - Parameter routeId: The ID of the route to fetch trips for
    /// - Returns: Array of Trip objects belonging to the specified route
    internal func fetchTripsFromNetwork(forRoute routeId: String) async throws -> [Foli.Trip] {
        try await dedup.performDeduplicated(.tripsForRoute(routeId)) { [self] in
            try await requestGTFS("/trips/route/\(routeId)", as: [Foli.Trip].self)
        }
    }

    /// Fetch GTFS trip metadata for a specific trip ID
    /// - Parameter tripId: The ID of the trip to fetch
    /// - Returns: The trip if found
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchTrip(tripId: String) async throws -> Foli.Trip? {
        _ = try await fetchTrips()
        return await indexes.trip(for: tripId)
    }
    
    // MARK: - Trips with Caching
    
    /// Fetch all trips using the client's configured caching behavior.
    /// - Returns: Array of Trip objects.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchTrips() async throws -> [Foli.Trip] {
        try await resolveCached(
            for: .trips,
            load: { [cache] in try await cache?.loadTrips() },
            loadStale: { [cache] in try await cache?.loadStaleTrips() },
            save: { [cache] trips in try await cache?.saveTrips(trips) },
            fetch: { [self] in try await fetchTripsFromNetwork() },
            rebuildIndex: { [self] trips in await indexes.rebuildTrips(using: trips) }
        )
    }

    /// Fetch trips for a specific route using the client's configured caching behavior.
    /// - Parameter routeId: The ID of the route to fetch trips for.
    /// - Returns: Array of Trip objects belonging to the specified route.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchTrips(forRoute routeId: String) async throws -> [Foli.Trip] {
        try await resolveCached(
            for: .tripsForRoute(routeId),
            load: { [cache] in try await cache?.loadTrips(forRoute: routeId) },
            loadStale: { [cache] in try await cache?.loadStaleTrips(forRoute: routeId) },
            save: { [cache] trips in try await cache?.saveTrips(trips, forRoute: routeId) },
            fetch: { [self] in try await fetchTripsFromNetwork(forRoute: routeId) },
            rebuildIndex: { [self] trips in await indexes.rebuildTrips(using: trips) }
        )
    }
}
