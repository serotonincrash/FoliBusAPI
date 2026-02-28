//
//  CacheResource.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

public extension Foli {
    /// Types of cacheable data
    enum CacheResource: Sendable {
        case routes
        case stops
        case trips
        case stopTimes
        case stopTimesForTrip(String)
        case stopTimesForStop(String)
    }
}
