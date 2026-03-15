import Foundation

// MARK: - Agency Model
/// Information about a transit agency (GTFS agency.txt)
public extension Foli {
    struct Agency: Codable, Sendable, Identifiable, Equatable {
        /// The GTFS agency_id value.
        public let id: String
        /// The GTFS agency_name value.
        public let agencyName: String
        /// The GTFS agency_url value.
        public let agencyUrl: String?
        /// The GTFS agency_timezone value.
        public let agencyTimezone: String?
        /// The GTFS agency_lang value.
        public let agencyLang: String?
        /// The GTFS agency_phone value.
        public let agencyPhone: String?
        /// The GTFS agency_fare_url value.
        public let agencyFareUrl: String?

        public init(
            id: String,
            agencyName: String,
            agencyUrl: String? = nil,
            agencyTimezone: String? = nil,
            agencyLang: String? = nil,
            agencyPhone: String? = nil,
            agencyFareUrl: String? = nil
        ) {
            self.id = id
            self.agencyName = agencyName
            self.agencyUrl = agencyUrl
            self.agencyTimezone = agencyTimezone
            self.agencyLang = agencyLang
            self.agencyPhone = agencyPhone
            self.agencyFareUrl = agencyFareUrl
        }

        enum CodingKeys: String, CodingKey {
            case id = "agency_id"
            case agencyName = "agency_name"
            case agencyUrl = "agency_url"
            case agencyTimezone = "agency_timezone"
            case agencyLang = "agency_lang"
            case agencyPhone = "agency_phone"
            case agencyFareUrl = "agency_fare_url"
        }
    }
}
