//
//  CacheBehavior.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

public extension Foli {
    /// Controls caching behavior for API requests
        enum CacheBehavior: Sendable {
            /// Use cached data if available and valid, otherwise fetch from network
            case cachedOrFetch
            
            /// Force fetch from network, ignoring cache (but update cache after)
            case forceRefresh
            
            /// Use only cached data, fail if not available or expired
            case cachedOnly
            
            /// Fetch from network without caching
            case noCache
        }

}
