//
//  FoliService+CalendarDates.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation
import FoliBusAPI

// MARK: - Calendar Dates API

public extension FoliService {
    
    /// Fetch all calendar date exceptions
    /// - Returns: Array of CalendarDate objects
    func fetchCalendarDates() async throws -> [Foli.CalendarDate] {
        return try await client.fetchCalendarDates()
    }
}
