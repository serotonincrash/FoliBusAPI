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
        
        // MARK: - Nested Types
        
        /// Metadata about a cached dataset
        private struct DatasetMetadata: Codable {
            let datasetId: String
            let cachedAt: Date
        }
        
        /// Response from the Föli GTFS API endpoint
        private struct GTFSInfoResponse: Codable {
            let latest: String
            let datasets: [String]
            
            enum CodingKeys: String, CodingKey {
                case latest
                case datasets
            }
        }
        
        /// Wrapper that combines metadata with cached data
        private struct CachedData<T: Codable>: Codable {
            let metadata: DatasetMetadata
            let data: T
        }
        
        // MARK: - Properties
        
        private let fileManager: FileManager
        private let cacheDirectory: URL
        public let timeoutDuration: Foli.CacheTimeout
        private let baseURL: String = "https://data.foli.fi/gtfs/v0"
        private let session: URLSession
        
        // MARK: - Initialization
        
        public init(
            timeout: Foli.CacheTimeout = .default,
            fileManager: FileManager = .default
        ) throws {
            self.timeoutDuration = timeout
            self.fileManager = fileManager
            self.session = URLSession.shared
            
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
        
        public func loadTrips(forRoute routeId: String) async throws -> [Foli.Trip]? {
            return try await load(type: .tripsForRoute(routeId))
        }
        
        public func saveTrips(_ trips: [Foli.Trip], forRoute routeId: String) async throws {
            try await save(trips, type: .tripsForRoute(routeId))
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
        
        public func loadCalendarDates() async throws -> [Foli.CalendarDate]? {
            return try await load(type: .calendarDates)
        }
        
        public func saveCalendarDates(_ calendarDates: [Foli.CalendarDate]) async throws {
            try await save(calendarDates, type: .calendarDates)
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
            
            // Load metadata from the cached file
            guard let metadata = try? await loadMetadata(for: type) else {
                return false
            }
            
            // Check time-based validity
            let age = Date().timeIntervalSince(metadata.cachedAt)
            let isTimeValid = age <= timeoutDuration.validityDuration
            
            if isTimeValid {
                // Cache is still within time window
                return true
            }
            
            // Time-based check failed - check if dataset has changed on server
            do {
                let latestDatasetId = try await fetchLatestDatasetId()
                
                // If the dataset ID matches, refresh the timestamp and consider cache valid
                if latestDatasetId == metadata.datasetId {
                    // Reload the data to refresh the metadata timestamp
                    try? await refreshMetadataTimestamp(for: type)
                    return true
                } else {
                    // New dataset available - invalidate cache
                    return false
                }
            } catch {
                // Network error or other issue - treat cache as valid to avoid breaking the app
                return true
            }
        }
        
        public func cacheAge(for type: Foli.CacheResource) async -> TimeInterval? {
            guard let metadata = try? await loadMetadata(for: type) else {
                return nil
            }
            return Date().timeIntervalSince(metadata.cachedAt)
        }
        
        public func currentDatasetId(for type: Foli.CacheResource?) async throws -> String? {
            if let type = type {
                // Return dataset ID for specific resource type
                return try await loadMetadata(for: type)?.datasetId
            } else {
                // Return the most recently cached dataset ID across all resources
                return try await loadMostRecentDatasetId()
            }
        }
        
        public var currentDatasetId: String? {
            get async throws {
                return try await currentDatasetId(for: nil)
            }
        }
        
        // MARK: - Private Methods
        
        private func load<T: Codable>(type: Foli.CacheResource) async throws -> T? {
            
            guard await hasValidCache(for: type) else {
                return nil
            }
            
            let fileURL = fileURL(for: type)
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            let data = try Data(contentsOf: fileURL)
            let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)
            return cachedData.data
        }
        
        private func save<T: Codable>(_ value: T, type: Foli.CacheResource) async throws {
            
            // Fetch the current dataset ID from the API
            let datasetId = try await fetchLatestDatasetId()
            
            // Create metadata with current dataset ID and timestamp
            let metadata = DatasetMetadata(
                datasetId: datasetId,
                cachedAt: Date()
            )
            
            // Wrap data with metadata
            let cachedData = CachedData(metadata: metadata, data: value)
            
            // Encode and save the wrapped data
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let data = try encoder.encode(cachedData)
            
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
            case .tripsForRoute(let routeId):
                filename = "trips_route_\(routeId).json"
            case .stopTimes:
                filename = "stop_times.json"
            case .stopTimesForTrip(let tripId):
                filename = "stop_times_trip_\(tripId).json"
            case .stopTimesForStop(let stopId):
                filename = "stop_times_stop_\(stopId).json"
            case .calendarDates:
                filename = "calendar_dates.json"
            }
            
            return cacheDirectory.appendingPathComponent(filename)
        }
        
        // MARK: - Metadata Methods
        
        /// Load only the metadata from a cached file (without loading the full data)
        private func loadMetadata(for type: Foli.CacheResource) async throws -> DatasetMetadata? {
            let fileURL = fileURL(for: type)
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            let data = try Data(contentsOf: fileURL)
            
            // Use a wrapper to decode just the metadata portion
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let metadataDict = json["metadata"] as? [String: Any],
               let metadataData = try? JSONSerialization.data(withJSONObject: metadataDict) {
                return try JSONDecoder().decode(DatasetMetadata.self, from: metadataData)
            }
            
            return nil
        }
        
        /// Refresh the metadata timestamp for a cached resource (keeping the same data and dataset ID)
        private func refreshMetadataTimestamp(for type: Foli.CacheResource) async throws {
            let fileURL = fileURL(for: type)
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return
            }
            
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            
            // Determine the type to decode
            let cachedData: any Codable
            switch type {
            case .routes:
                let temp = try decoder.decode(CachedData<[Foli.Route]>.self, from: data)
                cachedData = temp
            case .stops:
                let temp = try decoder.decode(CachedData<[Foli.Stop]>.self, from: data)
                cachedData = temp
            case .trips:
                let temp = try decoder.decode(CachedData<[Foli.Trip]>.self, from: data)
                cachedData = temp
            case .tripsForRoute:
                let temp = try decoder.decode(CachedData<[Foli.Trip]>.self, from: data)
                cachedData = temp
            case .stopTimes:
                let temp = try decoder.decode(CachedData<[Foli.StopTime]>.self, from: data)
                cachedData = temp
            case .stopTimesForTrip:
                let temp = try decoder.decode(CachedData<[Foli.StopTime]>.self, from: data)
                cachedData = temp
            case .stopTimesForStop:
                let temp = try decoder.decode(CachedData<[Foli.StopTime]>.self, from: data)
                cachedData = temp
            case .calendarDates:
                let temp = try decoder.decode(CachedData<[Foli.CalendarDate]>.self, from: data)
                cachedData = temp
            }
            
            // Create updated metadata with refreshed timestamp
            let oldMetadata: DatasetMetadata
            let newData: any Codable
            
            switch cachedData {
            case let cached as CachedData<[Foli.Route]>:
                oldMetadata = cached.metadata
                let newMetadata = DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date())
                newData = CachedData(metadata: newMetadata, data: cached.data)
            case let cached as CachedData<[Foli.Stop]>:
                oldMetadata = cached.metadata
                let newMetadata = DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date())
                newData = CachedData(metadata: newMetadata, data: cached.data)
            case let cached as CachedData<[Foli.Trip]>:
                oldMetadata = cached.metadata
                let newMetadata = DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date())
                newData = CachedData(metadata: newMetadata, data: cached.data)
            case let cached as CachedData<[Foli.StopTime]>:
                oldMetadata = cached.metadata
                let newMetadata = DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date())
                newData = CachedData(metadata: newMetadata, data: cached.data)
            case let cached as CachedData<[Foli.CalendarDate]>:
                oldMetadata = cached.metadata
                let newMetadata = DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date())
                newData = CachedData(metadata: newMetadata, data: cached.data)
            default:
                return
            }
            
            // Encode and save the updated cached data
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let updatedData = try encoder.encode(newData)
            try updatedData.write(to: fileURL, options: .atomic)
        }
        
        /// Find the most recently cached dataset ID across all resources
        private func loadMostRecentDatasetId() async throws -> String? {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )
            
            var mostRecentDatasetId: String?
            var mostRecentDate: Date?
            
            for url in contents {
                guard url.pathExtension == "json" else { continue }
                
                do {
                    let metadata = try await loadMetadataFromURL(url)
                    
                    if mostRecentDate == nil || metadata.cachedAt > mostRecentDate! {
                        mostRecentDate = metadata.cachedAt
                        mostRecentDatasetId = metadata.datasetId
                    }
                } catch {
                    // Skip files that can't be decoded
                    continue
                }
            }
            
            return mostRecentDatasetId
        }
        
        /// Load metadata from a specific URL
        private func loadMetadataFromURL(_ url: URL) async throws -> DatasetMetadata {
            let data = try Data(contentsOf: url)
            
            // Parse just the metadata portion
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let metadataDict = json["metadata"] as? [String: Any],
               let metadataData = try? JSONSerialization.data(withJSONObject: metadataDict) {
                return try JSONDecoder().decode(DatasetMetadata.self, from: metadataData)
            }
            
            throw Foli.APIError.decodingError(CodingError.invalidMetadata)
        }
        
        private enum CodingError: Error {
            case invalidMetadata
        }
        
        /// Fetch the latest dataset ID from the Föli API
        private func fetchLatestDatasetId() async throws -> String {
            guard let url = URL(string: baseURL) else {
                throw Foli.APIError.invalidURL
            }
            
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw Foli.APIError.invalidResponse
            }
            
            let gtfsInfo = try JSONDecoder().decode(GTFSInfoResponse.self, from: data)
            return gtfsInfo.latest
        }
    }
}
