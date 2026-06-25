import Foundation

// MARK: - Calendar List Response
extension Foli {
    /// Response containing weekly calendars (GTFS calendar.txt)
    struct CalendarList: Codable, Sendable, Equatable, Hashable {
        /// Array of decoded weekly service calendars.
        let calendars: [Foli.Calendar]
        
        /// Calendar payload entry in the documented dictionary response format.
        struct APICalendarEntry: Codable, Sendable {
            let monday: Bool
            let tuesday: Bool
            let wednesday: Bool
            let thursday: Bool
            let friday: Bool
            let saturday: Bool
            let sunday: Bool
            let startDate: String
            let endDate: String
            
            init(calendar: Foli.Calendar) {
                self.monday = calendar.monday
                self.tuesday = calendar.tuesday
                self.wednesday = calendar.wednesday
                self.thursday = calendar.thursday
                self.friday = calendar.friday
                self.saturday = calendar.saturday
                self.sunday = calendar.sunday
                self.startDate = calendar.startDate
                self.endDate = calendar.endDate
            }
            
            enum CodingKeys: String, CodingKey {
                case monday
                case tuesday
                case wednesday
                case thursday
                case friday
                case saturday
                case sunday
                case startDate = "start_date"
                case endDate = "end_date"
            }
        }
        
        init(calendars: [Foli.Calendar]) {
            self.calendars = calendars
        }
        
        /// Decodes both documented dictionary payloads and legacy array payloads.
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let dictionary = try? container.decode([String: APICalendarEntry].self) {
                self.calendars = dictionary
                    .map { serviceId, entry in
                        Foli.Calendar(
                            id: serviceId,
                            monday: entry.monday,
                            tuesday: entry.tuesday,
                            wednesday: entry.wednesday,
                            thursday: entry.thursday,
                            friday: entry.friday,
                            saturday: entry.saturday,
                            sunday: entry.sunday,
                            startDate: entry.startDate,
                            endDate: entry.endDate
                        )
                    }
                    .sorted { $0.id < $1.id }
                return
            }
            
            let array = try container.decode([Foli.Calendar].self)
            self.calendars = array.sorted { $0.id < $1.id }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            var dictionary: [String: APICalendarEntry] = [:]
            for calendar in calendars {
                dictionary[calendar.id] = APICalendarEntry(calendar: calendar)
            }
            try container.encode(dictionary)
        }
    }
}
