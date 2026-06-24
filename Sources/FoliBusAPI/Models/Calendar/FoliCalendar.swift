import Foundation

// MARK: - Calendar Model
/// Weekly service calendar record (GTFS calendar.txt)
public extension Foli {
    /// Weekly service schedule metadata keyed by GTFS `service_id`.
    struct Calendar: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// The GTFS `service_id`.
        public let id: String
        /// Whether the service is active on Mondays.
        public let monday: Bool
        /// Whether the service is active on Tuesdays.
        public let tuesday: Bool
        /// Whether the service is active on Wednesdays.
        public let wednesday: Bool
        /// Whether the service is active on Thursdays.
        public let thursday: Bool
        /// Whether the service is active on Fridays.
        public let friday: Bool
        /// Whether the service is active on Saturdays.
        public let saturday: Bool
        /// Whether the service is active on Sundays.
        public let sunday: Bool
        /// The first service date in `YYYYMMDD` format.
        public let startDate: String
        /// The last service date in `YYYYMMDD` format.
        public let endDate: String

        /// Creates a weekly service calendar record.
        public init(
            id: String,
            monday: Bool,
            tuesday: Bool,
            wednesday: Bool,
            thursday: Bool,
            friday: Bool,
            saturday: Bool,
            sunday: Bool,
            startDate: String,
            endDate: String
        ) {
            self.id = id
            self.monday = monday
            self.tuesday = tuesday
            self.wednesday = wednesday
            self.thursday = thursday
            self.friday = friday
            self.saturday = saturday
            self.sunday = sunday
            self.startDate = startDate
            self.endDate = endDate
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            monday = try Self.decodeFlag(from: container, forKey: .monday)
            tuesday = try Self.decodeFlag(from: container, forKey: .tuesday)
            wednesday = try Self.decodeFlag(from: container, forKey: .wednesday)
            thursday = try Self.decodeFlag(from: container, forKey: .thursday)
            friday = try Self.decodeFlag(from: container, forKey: .friday)
            saturday = try Self.decodeFlag(from: container, forKey: .saturday)
            sunday = try Self.decodeFlag(from: container, forKey: .sunday)
            startDate = try container.decode(String.self, forKey: .startDate)
            endDate = try container.decode(String.self, forKey: .endDate)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(monday, forKey: .monday)
            try container.encode(tuesday, forKey: .tuesday)
            try container.encode(wednesday, forKey: .wednesday)
            try container.encode(thursday, forKey: .thursday)
            try container.encode(friday, forKey: .friday)
            try container.encode(saturday, forKey: .saturday)
            try container.encode(sunday, forKey: .sunday)
            try container.encode(startDate, forKey: .startDate)
            try container.encode(endDate, forKey: .endDate)
        }

        enum CodingKeys: String, CodingKey {
            case id = "service_id"
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

        private static func decodeFlag(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> Bool {
            if let boolValue = try? container.decode(Bool.self, forKey: key) {
                return boolValue
            }
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return intValue != 0
            }
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Expected Bool or Int for calendar weekday flag."
            )
        }
    }
}
