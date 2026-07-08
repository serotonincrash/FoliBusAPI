import Foundation

// MARK: - Agency Model
/// Information about a transit agency (GTFS agency.txt).
///
/// Agencies operate one or more routes and provide contact information
/// and service details for passengers.
public extension Foli {
    struct Agency: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// The GTFS `agency_id` value.
        public let id: String
        /// The full agency name (GTFS `agency_name`).
        public let name: String
        /// The agency's website URL (GTFS `agency_url`).
        public let url: String?
        /// The timezone where the agency operates (GTFS `agency_timezone`).
        public let agencyTimezone: String?
        /// Primary language used by the agency (GTFS `agency_lang`).
        public let agencyLang: String?
        /// Customer service phone number (GTFS `agency_phone`).
        public let agencyPhone: String?
        /// URL for fare information (GTFS `agency_fare_url`).
        public let agencyFareUrl: String?

        /// Creates an agency value.
        /// - Parameters:
        ///   - id: The GTFS `agency_id` value.
        ///   - name: The GTFS `agency_name` value.
        ///   - url: Optional GTFS `agency_url` value.
        ///   - agencyTimezone: Optional GTFS `agency_timezone` value.
        ///   - agencyLang: Optional GTFS `agency_lang` value.
        ///   - agencyPhone: Optional GTFS `agency_phone` value.
        ///   - agencyFareUrl: Optional GTFS `agency_fare_url` value.
        public init(
            id: String,
            name: String,
            url: String? = nil,
            agencyTimezone: String? = nil,
            agencyLang: String? = nil,
            agencyPhone: String? = nil,
            agencyFareUrl: String? = nil
        ) {
            self.id = id
            self.name = name
            self.url = url
            self.agencyTimezone = agencyTimezone
            self.agencyLang = agencyLang
            self.agencyPhone = agencyPhone
            self.agencyFareUrl = agencyFareUrl
        }

        private enum CodingKeys: String, CodingKey {
            case id = "agency_id"
            case name = "agency_name"
            case url = "agency_url"
            case agencyTimezone = "agency_timezone"
            case agencyLang = "agency_lang"
            case agencyPhone = "agency_phone"
            case agencyFareUrl = "agency_fare_url"
        }
    }
}
