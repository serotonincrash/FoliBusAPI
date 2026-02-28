//
//  FoliDiskCache.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

public extension Foli {
    
    /// File-based cache implementation for GTFS data
    /// 
    /// Uses actor isolation to ensure thread-safe file operations.
    /// All methods are async to perform file I/O without blocking.
    actor DiskCache: Foli.Cache {
        
        // MARK: - Properties
        
        private let fileManager: FileManager
        private let cacheDirectory: URL
        private let configuration: Foli.CacheConfiguration
        
        // MARK: - Initialization
        
        public init(
            configuration: Foli.CacheConfiguration = .default,
            fileManager: FileManager = .default
        ) throws {
            self.configuration = configuration
            self.fileManager = fileManager
            
            // Create cache directory in Application Support
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            self.cacheDirectory = appSupportURL
                .appendingPathComponent("FoliBusAPI", isDirectory: true)
                .appendingPathComponent("Cache", isDirectory: true)
            
            // Create cache directory if it doesn't exist
            try fileManager.createDirectory(
                at: self.cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // MARK: - Public Methods
        
        public func loadRoutes() async throws -> [Foli.Route]? {
            return try await load(type: .routes)
        }
        
        public func saveRoutes(_ routes: [Foli.Route]) async throws {
            try await save(routes, type: .routes)
        }
        
        public func loadStops() async throws -> [Foli.Stop]? {
            return try await load(type: .stops)
        }
        
        public func saveStops(_ stops: [Foli.Stop]) async throws {
            try await save(stops, type: .stops)
        }
        
        public func loadTrips() async throws -> [Foli.Trip]? {
            return try await load(type: .trips)
        }
        
        public func saveTrips(_ trips: [Foli.Trip]) async throws {
            try await save(trips, type: .trips)
        }
        
        public func loadStopTimes() async throws -> [Foli.StopTime]? {
            return try await load(type: .stopTimes)
        }
        
        public func saveStopTimes(_ stopTimes: [Foli.StopTime]) async throws {
            try await save(stopTimes, type: .stopTimes)
        }
        
        public func loadStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? {
            return try await load(type: .stopTimesForTrip(tripId))
        }
        
        public func saveStopTimes(_ stopTimes: [Foli.StopTime], forTrip tripId: String) async throws {
            try await save(stopTimes, type: .stopTimesForTrip(tripId))
        }
        
        public func loadStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? {
            return try await load(type: .stopTimesForStop(stopId))
        }
        
        public func saveStopTimes(_ stopTimes: [Foli.StopTime], forStop stopId: String) async throws {
            try await save(stopTimes, type: .stopTimesForStop(stopId))
        }
        
        public func clearAllCache() async throws {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )
            
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }
        
        public func clearCache(for type: Foli.CacheResource) async throws {
            let fileURL = fileURL(for: type)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }
        
        public func hasValidCache(for type: Foli.CacheResource) async -> Bool {
            guard configuration.isEnabled else { return false }
            
            guard let age = await cacheAge(for: type) else { return false }
            return age <= configuration.validityDuration
        }
        
        public func cacheAge(for type: Foli.CacheResource) async -> TimeInterval? {
            let fileURL = fileURL(for: type)
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                return nil
            }
            
            return Date().timeIntervalSince(modificationDate)
        }
        
        // MARK: - Private Methods
        
        private func load<T: Codable>(type: Foli.CacheResource) async throws -> T? {
            guard configuration.isEnabled else { return nil }
            
            let fileURL = fileURL(for: type)
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            guard await hasValidCache(for: type) else {
                // Optionally delete stale cache
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
            
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        }
        
        private func save<T: Codable>(_ value: T, type: Foli.CacheResource) async throws {
            guard configuration.isEnabled else { return }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let data = try encoder.encode(value)
            
            let fileURL = fileURL(for: type)
            try data.write(to: fileURL, options: .atomic)
        }
        
        private func fileURL(for type: Foli.CacheResource) -> URL {
            let filename: String
            
            switch type {
            case .routes:
                filename = "routes.json"
            case .stops:
                filename = "stops.json"
            case .trips:
                filename = "trips.json"
            case .stopTimes:
                filename = "stop_times.json"
            case .stopTimesForTrip(let tripId):
                filename = "stop_times_trip_\(tripId).json"
            case .stopTimesForStop(let stopId):
                filename = "stop_times_stop_\(stopId).json"
            }
            
            return cacheDirectory.appendingPathComponent(filename)
        }
    }
}
