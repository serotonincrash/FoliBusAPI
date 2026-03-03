//
//  Foli+CalendarDate.swift
//  FoliBusAPI
//
//  Created by sero on 27/2/26.
//

import Foundation

// MARK: - Calendar Date Model
/// Information about service exceptions for a specific date (GTFS calendar\_dates.txt)
public extension Foli {
    
    struct CalendarDate: Codable, Sendable, Identifiable, Equatable {
        public let id = UUID()
        
        /// The service ID that this exception applies to
        public let serviceId: String
        
        /// Date in YYYYMMDD format
        public let dateString: String
        
        /// Exception type: 0 = service removed, 1 = service added
        public let exceptionType: Int
        
        public enum CodingKeys: String, CodingKey {
            case serviceId = "service_id"
            case dateString = "date"
            case exceptionType = "exception_type"
        }
        
        public init(serviceId: String, dateString: String, exceptionType: Int) {
            self.serviceId = serviceId
            self.dateString = dateString
            self.exceptionType = exceptionType
        }
        
        // MARK: - Computed Properties
        
        /// The date as a Date object, if the dateString is valid
        public var date: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            formatter.calendar = Calendar(identifier: .gregorian)
            return formatter.date(from: dateString)
        }
        
        /// Whether this exception adds service for this date
        public var isServiceAdded: Bool {
            return exceptionType == 1
        }
        
        /// Whether this exception removes service for this date
        public var isServiceRemoved: Bool {
            return exceptionType == 0
        }
    }
}

// MARK: - Calendar Dates List Response
/// Response containing all calendar date exceptions (GTFS calendar_dates.txt)
/// The API returns a dictionary where keys are service IDs and values are arrays of date exceptions
public struct FoliCalendarDatesList: Codable {
    /// Array of all calendar date exceptions across all services
    public let calendarDates: [Foli.CalendarDate]
    
    public init(calendarDates: [Foli.CalendarDate]) {
        self.calendarDates = calendarDates
    }
    
    // MARK: - API Decoding Helper
    /// Helper struct to decode individual calendar date entries from the API
    struct APICalendarDateEntry: Codable {
        let date: String
        let exception_type: Int
    }
    
    /// Decode from the API format: dictionary with service IDs as keys
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: [APICalendarDateEntry]].self)
        
        var allDates: [Foli.CalendarDate] = []
        
        for (serviceId, entries) in dictionary {
            for entry in entries {
                let calendarDate = Foli.CalendarDate(
                    serviceId: serviceId,
                    dateString: entry.date,
                    exceptionType: entry.exception_type
                )
                allDates.append(calendarDate)
            }
        }
        
        self.calendarDates = allDates.sorted { $0.dateString < $1.dateString }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var dictionary: [String: [APICalendarDateEntry]] = [:]
        
        for calendarDate in calendarDates {
            let entry = APICalendarDateEntry(
                date: calendarDate.dateString,
                exception_type: calendarDate.exceptionType
            )
            
            if dictionary[calendarDate.serviceId] == nil {
                dictionary[calendarDate.serviceId] = []
            }
            dictionary[calendarDate.serviceId]?.append(entry)
        }
        
        try container.encode(dictionary)
    }
}
