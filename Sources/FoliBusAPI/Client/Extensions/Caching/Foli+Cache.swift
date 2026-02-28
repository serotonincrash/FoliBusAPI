//
//  FoliCache.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

public extension Foli {
    /// Protocol for caching GTFS data locally
    /// 
    /// All methods are async to prevent blocking and support actor-isolated implementations.
    protocol Cache: Sendable {
        /// Load cached routes if available and not expired
        func loadRoutes() async throws -> [Foli.Route]?
        
        /// Save routes to cache with current timestamp
        func saveRoutes(_ routes: [Foli.Route]) async throws
        
        /// Load cached stops if available and not expired
        func loadStops() async throws -> [Foli.Stop]?
        
        /// Save stops to cache with current timestamp
        func saveStops(_ stops: [Foli.Stop]) async throws
        
        /// Load cached trips if available and not expired
        func loadTrips() async throws -> [Foli.Trip]?
        
        /// Save trips to cache with current timestamp
        func saveTrips(_ trips: [Foli.Trip]) async throws
        
        /// Load cached stop times if available and not expired
        func loadStopTimes() async throws -> [Foli.StopTime]?
        
        /// Save stop times to cache with current timestamp
        func saveStopTimes(_ stopTimes: [Foli.StopTime]) async throws
        
        /// Load cached stop times for a specific trip
        func loadStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]?
        
        /// Save stop times for a specific trip
        func saveStopTimes(_ stopTimes: [Foli.StopTime], forTrip tripId: String) async throws
        
        /// Load cached stop times for a specific stop
        func loadStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]?
        
        /// Save stop times for a specific stop
        func saveStopTimes(_ stopTimes: [Foli.StopTime], forStop stopId: String) async throws
        
        /// Clear all cached data
        func clearAllCache() async throws
        
        /// Clear cached data for a specific type
        func clearCache(for type: Foli.CacheResource) async throws
        
        /// Check if cached data exists and is valid (not expired)
        func hasValidCache(for type: Foli.CacheResource) async -> Bool
        
        /// Get the age of cached data in seconds, or nil if not cached
        func cacheAge(for type: Foli.CacheResource) async -> TimeInterval?
        
    }
}
