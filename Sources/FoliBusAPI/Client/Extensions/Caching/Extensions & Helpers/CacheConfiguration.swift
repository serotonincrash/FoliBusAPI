//
//  CacheConfiguration.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

public extension Foli {
    /// Cache configuration
    struct CacheConfiguration: Sendable {
        /// Default cache validity duration in seconds (24 hours)
        public static let defaultValidityDuration: TimeInterval = 24 * 60 * 60
        
        /// How long cached data remains valid before requiring a refresh
        public let validityDuration: TimeInterval
        
        /// Enable/disable caching
        public let isEnabled: Bool
        
        public init(
            validityDuration: TimeInterval = defaultValidityDuration,
            isEnabled: Bool = true
        ) {
            self.validityDuration = validityDuration
            self.isEnabled = isEnabled
        }
        
        public static let `default` = CacheConfiguration()
        public static let disabled = CacheConfiguration(isEnabled: false)
        public static let shortLived = CacheConfiguration(validityDuration: 60 * 60) // 1 hour
        public static let longLived = CacheConfiguration(validityDuration: 7 * 24 * 60 * 60) // 7 days
    }
}
