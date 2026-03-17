import Foundation

// MARK: - Calendar Dates List Response
public extension Foli {
    /// Response containing all calendar date exceptions (GTFS calendar_dates.txt)
    /// The API returns a dictionary where keys are service IDs and values are arrays of date exceptions
    struct CalendarDatesList: Codable, Sendable {
        /// Array of all calendar date exceptions across all services
        public let calendarDates: [Foli.CalendarDate]

        public init(calendarDates: [Foli.CalendarDate]) {
            self.calendarDates = calendarDates
        }

        // MARK: - API Decoding Helper
        /// Helper struct to decode individual calendar date entries from the API
        struct APICalendarDateEntry: Codable, Sendable {
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
}
