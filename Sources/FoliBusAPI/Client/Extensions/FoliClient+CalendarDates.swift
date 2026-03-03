//
//  FoliClient+CalendarDates.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Calendar Dates (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch all GTFS calendar date exceptions
    /// - Returns: Array of CalendarDate objects
    func fetchCalendarDatesFromNetwork() async throws -> [Foli.CalendarDate] {
        let url = try makeGTFSEndpointURL(path: "/calendar_dates")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }
        
        do {
            let calendarDatesList = try JSONDecoder().decode(FoliCalendarDatesList.self, from: data)
            return calendarDatesList.calendarDates
        } catch {
            throw Foli.APIError.decodingError(error)
        }
    }
    
    // MARK: - Calendar Dates with Caching
    
    /// Fetch calendar dates with optional caching control
    /// - Returns: Array of CalendarDate objects
    func fetchCalendarDates() async throws -> [Foli.CalendarDate] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadCalendarDates() {
                return cached
            }
            fallthrough
            
        case .forceRefresh:
            let calendarDates = try await fetchCalendarDatesFromNetwork()
            try? await cache?.saveCalendarDates(calendarDates)
            return calendarDates
            
        case .cachedOnly:
            guard let cached = try await cache?.loadCalendarDates() else {
                throw Foli.APIError.noData
            }
            return cached
            
        case .noCache:
            return try await fetchCalendarDatesFromNetwork()
        }
    }
}
