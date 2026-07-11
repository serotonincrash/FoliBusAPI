//
//  FoliClient+CalendarDates.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Calendar Dates (GTFS)

public extension FoliClient {
    
    /// Fetch all GTFS calendar date exceptions
    /// - Returns: Array of CalendarDate objects
    internal func fetchCalendarDatesFromNetwork() async throws -> [Foli.CalendarDate] {
        try await dedup.performDeduplicated(forKey: .resource(.calendarDates)) { [self] in
            let calendarDatesList = try await requestGTFS("/calendar_dates", as: Foli.CalendarDatesList.self)
            return calendarDatesList.calendarDates
        }
    }
    
    // MARK: - Calendar Dates with Caching
    
    /// Fetch calendar dates using the client's configured caching behavior.
    /// - Returns: Array of CalendarDate objects.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchCalendarDates() async throws -> [Foli.CalendarDate] {
        try await resolveCached(
            for: .calendarDates,
            load: { [cache] in try await cache?.loadCalendarDates() },
            loadStale: { [cache] in try await cache?.loadStaleCalendarDates() },
            save: { [cache] calendarDates, datasetId in try await cache?.saveCalendarDates(calendarDates, datasetId: datasetId) },
            fetch: { [self] in try await fetchCalendarDatesFromNetwork() }
        )
    }
}
