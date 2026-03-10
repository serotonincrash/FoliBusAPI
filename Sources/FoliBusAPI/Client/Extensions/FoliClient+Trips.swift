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
        try await requestGTFS("/trips", as: [Foli.Trip].self)
    }
    
    /// Fetch GTFS trips for a specific route
    /// - Parameter routeId: The ID of the route to fetch trips for
    /// - Returns: Array of Trip objects belonging to the specified route
    func fetchTripsFromNetwork(forRoute routeId: String) async throws -> [Foli.Trip] {
        try await requestGTFS("/trips/route/\(routeId)", as: [Foli.Trip].self)
    }
    
    // MARK: - Trips with Caching
    
    /// Fetch trips with optional caching control
    /// - Returns: Array of Trip objects
    func fetchTrips() async throws -> [Foli.Trip] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadTrips() {
                return cached
            }
            // fallthrough to fetch
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
    
    /// Fetch trips for a specific route with optional caching control
    /// - Parameter routeId: The ID of the route to fetch trips for
    /// - Returns: Array of Trip objects belonging to the specified route
    func fetchTrips(forRoute routeId: String) async throws -> [Foli.Trip] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadTrips(forRoute: routeId) {
                return cached
            }
            // fallthrough to fetch
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
