//
//  CacheConfiguration.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

public extension Foli {
    /// Configuration describing how long cached GTFS resources remain fresh.
    struct CacheTimeout: Sendable {
        /// Default cache validity duration in seconds (24 hours).
        public static let defaultValidityDuration: TimeInterval = 24 * 60 * 60
        
        /// How long cached data remains valid before requiring a refresh.
        public let validityDuration: TimeInterval
        
        /// Creates a cache-timeout configuration.
        /// - Parameter validityDuration: The freshness window, in seconds.
        public init(
            validityDuration: TimeInterval = defaultValidityDuration,
        ) {
            self.validityDuration = validityDuration
        }
        
        /// A default 24-hour cache lifetime.
        public static let `default` = CacheTimeout()
        /// A 1-hour cache lifetime for more frequently changing data.
        public static let shortLived = CacheTimeout(validityDuration: 60 * 60)
        /// A 7-day cache lifetime for rarely changing data.
        public static let longLived = CacheTimeout(validityDuration: 7 * 24 * 60 * 60)
    }
}
