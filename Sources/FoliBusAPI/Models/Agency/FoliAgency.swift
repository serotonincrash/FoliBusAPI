import Foundation

// MARK: - Agency Model
/// Information about a transit agency (GTFS agency.txt).
///
/// - SeeAlso: ``Foli/Route``
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
        public let timezone: String?
        /// Primary language used by the agency (GTFS `agency_lang`).
        public let language: String?
        /// Customer service phone number (GTFS `agency_phone`).
        public let phone: String?
        /// URL for fare information (GTFS `agency_fare_url`).
        public let fareUrl: String?

        /// Creates an agency value.
        /// - Parameters:
        ///   - id: The GTFS `agency_id` value.
        ///   - name: The GTFS `agency_name` value.
        ///   - url: Optional GTFS `agency_url` value.
        ///   - timezone: Optional GTFS `agency_timezone` value.
        ///   - language: Optional GTFS `agency_lang` value.
        ///   - phone: Optional GTFS `agency_phone` value.
        ///   - fareUrl: Optional GTFS `agency_fare_url` value.
        public init(
            id: String,
            name: String,
            url: String? = nil,
            timezone: String? = nil,
            language: String? = nil,
            phone: String? = nil,
            fareUrl: String? = nil
        ) {
            self.id = id
            self.name = name
            self.url = url
            self.timezone = timezone
            self.language = language
            self.phone = phone
            self.fareUrl = fareUrl
        }

        private enum CodingKeys: String, CodingKey {
            case id = "agency_id"
            case name = "agency_name"
            case url = "agency_url"
            case timezone = "agency_timezone"
            case language = "agency_lang"
            case phone = "agency_phone"
            case fareUrl = "agency_fare_url"
        }
    }
}
