//
//  CacheBehavior.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

public extension Foli {
    /// Controls how ``FoliClient`` uses cached GTFS resources.
    enum CacheBehavior: Sendable {
        /// Use cached data if available and still validated as current; otherwise fetch from the network.
        case cachedOrFetch

        /// Return stale cached data immediately and refresh it in the background.
        case staleWhileRevalidate
        
        /// Always fetch from the network and refresh the cache with the new value.
        case forceRefresh
        
        /// Use only cached data and fail if no valid cached value exists.
        case cachedOnly
        
        /// Fetch from the network without reading or writing cache entries.
        case noCache
    }

}
