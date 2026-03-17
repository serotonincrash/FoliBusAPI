import Foundation

// MARK: - Foli.Stop Model
/// Information about a single stop (GTFS-compliant)
public extension Foli {
    struct Stop: Codable, Sendable, Identifiable, Equatable {
        /// The unique identifier for the stop (GTFS `stop_id`)
        public let id: String
        /// The human-readable name of the stop (GTFS `stop_name`)
        public let name: String
        /// The stop code (GTFS `stop_code`) - often empty for Föli bus API. Use `id` instead.
        public let code: String?
        /// Latitude of the stop location (WGS-84) (GTFS stop_lat)
        public let latitude: Double?
        /// Longitude of the stop location (WGS-84) (GTFS stop_lon)
        public let longitude: Double?
        /// Zone identifier for the stop (GTFS zone_id)
        public let zoneId: String?
        /// Type of location (GTFS location_type) - 0=Stop, 1=Station, etc.
        public let locationType: Int?
        /// Parent station ID (GTFS parent_station)
        public let parentStation: String?
        /// Wheelchair boarding information (GTFS wheelchair_boarding)
        public let wheelchairBoarding: Int?

        /// Creates a stop value using GTFS stop fields.
        /// - Parameters:
        ///   - id: The GTFS `stop_id` value.
        ///   - name: The GTFS `stop_name` value.
        ///   - code: Optional GTFS `stop_code` value.
        ///   - latitude: Optional GTFS `stop_lat` value.
        ///   - longitude: Optional GTFS `stop_lon` value.
        ///   - zoneId: Optional GTFS `zone_id` value.
        ///   - locationType: Optional GTFS `location_type` value.
        ///   - parentStation: Optional GTFS `parent_station` value.
        ///   - wheelchairBoarding: Optional GTFS `wheelchair_boarding` value.
        public init(
            id: String,
            name: String,
            code: String? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil,
            zoneId: String? = nil,
            locationType: Int? = nil,
            parentStation: String? = nil,
            wheelchairBoarding: Int? = nil
        ) {
            self.id = id
            self.name = name
            self.code = code
            self.latitude = latitude
            self.longitude = longitude
            self.zoneId = zoneId
            self.locationType = locationType
            self.parentStation = parentStation
            self.wheelchairBoarding = wheelchairBoarding
        }

        enum CodingKeys: String, CodingKey {
            case id
            case name = "stop_name"
            case code = "stop_code"
            case latitude = "stop_lat"
            case longitude = "stop_lon"
            case zoneId = "zone_id"
            case locationType = "location_type"
            case parentStation = "parent_station"
            case wheelchairBoarding = "wheelchair_boarding"
        }

        // MARK: - Computed Properties

        /// Whether the stop has valid coordinates
        public var hasLocation: Bool {
            return latitude != nil && longitude != nil
        }

        /// Location coordinates if available
        public var location: Foli.Coordinate? {
            guard let lat = latitude, let lon = longitude else {
                return nil
            }
            return Foli.Coordinate(latitude: lat, longitude: lon)
        }

        /// Display name including stop code if available
        public var displayName: String {
            if let code = code, !code.isEmpty {
                return "\(code) \(name)"
            }
            return name
        }
    }
}
