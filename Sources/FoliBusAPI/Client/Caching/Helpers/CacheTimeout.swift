//
//  CacheTimeout.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Cache TTL Configuration
public extension Foli {
    /// Configuration describing how long cached GTFS resources remain fresh (TTL = Time To Live).
    ///
    /// Use this type to control how aggressively the client refreshes cached data.
    /// Shorter durations ensure fresher data but increase network usage.
    ///
    /// ## Predefined Configurations
    /// - ``default``: 24-hour validity for typical usage
    /// - ``shortLived``: 1-hour validity for frequently changing data
    /// - ``longLived``: 7-day validity for stable data
    ///
    /// ## Example
    /// ```swift
    /// // Use short-lived cache for development
    /// let client = try FoliClient(cacheTTL: .shortLived)
    ///
    /// // Use long-lived cache for stable environments
    /// let client = try FoliClient(cacheTTL: .longLived)
    /// ```
    struct CacheTTL: Sendable {
        /// Default cache validity duration in seconds (24 hours).
        public static let defaultValidityDuration: TimeInterval = 24 * 60 * 60
        
        /// How long cached data remains valid before requiring a refresh.
        public let validityDuration: TimeInterval
        
        /// Creates a cache TTL configuration.
        /// - Parameter validityDuration: The freshness window, in seconds.
        public init(validityDuration: TimeInterval = defaultValidityDuration) {
            self.validityDuration = validityDuration
        }
        
        /// A default 24-hour cache lifetime.
        ///
        /// Suitable for most production use cases where GTFS data is updated daily.
        public static let `default` = CacheTTL()
        
        /// A 1-hour cache lifetime for more frequently changing data.
        ///
        /// Useful during development or when GTFS data updates frequently.
        public static let shortLived = CacheTTL(validityDuration: 60 * 60)
        
        /// A 7-day cache lifetime for rarely changing data.
        ///
        /// Suitable for stable deployments where minimizing network traffic is important.
        public static let longLived = CacheTTL(validityDuration: 7 * 24 * 60 * 60)
    }
}
