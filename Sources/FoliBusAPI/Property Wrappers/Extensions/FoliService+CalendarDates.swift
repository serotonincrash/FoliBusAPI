//
//  FoliService+CalendarDates.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Calendar Dates API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all calendar date exceptions
    /// - Returns: Array of CalendarDate objects
    func fetchCalendarDates() async throws -> [Foli.CalendarDate] {
        return try await client.fetchCalendarDates()
    }
}
