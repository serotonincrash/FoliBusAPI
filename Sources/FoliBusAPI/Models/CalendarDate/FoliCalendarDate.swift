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
            formatter.calendar = Foundation.Calendar(identifier: .gregorian)
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
