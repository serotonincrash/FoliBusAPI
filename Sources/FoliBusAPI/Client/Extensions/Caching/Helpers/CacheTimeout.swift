//
//  CacheConfiguration.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

public extension Foli {
    /// Cache configuration
    struct CacheTimeout: Sendable {
        /// Default cache validity duration in seconds (24 hours)
        public static let defaultValidityDuration: TimeInterval = 24 * 60 * 60
        
        /// How long cached data remains valid before requiring a refresh
        public let validityDuration: TimeInterval
        
        public init(
            validityDuration: TimeInterval = defaultValidityDuration,
        ) {
            self.validityDuration = validityDuration
        }
        
        public static let `default` = CacheTimeout()
        public static let shortLived = CacheTimeout(validityDuration: 60 * 60) // 1 hour
        public static let longLived = CacheTimeout(validityDuration: 7 * 24 * 60 * 60) // 7 days
    }
}
