import Foundation

// MARK: - Foli.Stop Model
/// Information about a single stop (GTFS-compliant)
public extension Foli {
    struct Stop: Codable, Sendable, Identifiable, Equatable {
        /// The unique identifier for the stop (GTFS `stop_id`)
        public let id: String
        /// The human-readable name of the stop (GTFS `stop_name`)
        public let stopName: String
        /// The stop code (GTFS `stop_code`) - often empty for Föli bus API. Use `id` instead.
        public let stopCode: String?
        /// Latitude of the stop location (WGS-84) (GTFS stop_lat)
        public let stopLat: Double?
        /// Longitude of the stop location (WGS-84) (GTFS stop_lon)
        public let stopLon: Double?
        /// Zone identifier for the stop (GTFS zone_id)
        public let zoneId: String?
        /// Type of location (GTFS location_type) - 0=Stop, 1=Station, etc.
        public let locationType: Int?
        /// Parent station ID (GTFS parent_station)
        public let parentStation: String?
        /// Wheelchair boarding information (GTFS wheelchair_boarding)
        public let wheelchairBoarding: Int?

        public init(
            id: String,
            stopName: String,
            stopCode: String? = nil,
            stopLat: Double? = nil,
            stopLon: Double? = nil,
            zoneId: String? = nil,
            locationType: Int? = nil,
            parentStation: String? = nil,
            wheelchairBoarding: Int? = nil
        ) {
            self.id = id
            self.stopName = stopName
            self.stopCode = stopCode
            self.stopLat = stopLat
            self.stopLon = stopLon
            self.zoneId = zoneId
            self.locationType = locationType
            self.parentStation = parentStation
            self.wheelchairBoarding = wheelchairBoarding
        }

        enum CodingKeys: String, CodingKey {
            case id
            case stopName = "stop_name"
            case stopCode = "stop_code"
            case stopLat = "stop_lat"
            case stopLon = "stop_lon"
            case zoneId = "zone_id"
            case locationType = "location_type"
            case parentStation = "parent_station"
            case wheelchairBoarding = "wheelchair_boarding"
        }

        // MARK: - Computed Properties

        /// Whether the stop has valid coordinates
        public var hasLocation: Bool {
            return stopLat != nil && stopLon != nil
        }

        /// Location coordinates if available
        public var location: CLLocationCoordinate2D? {
            guard let lat = stopLat, let lon = stopLon else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        /// Display name including stop code if available
        public var displayName: String {
            if let code = stopCode, !code.isEmpty {
                return "\(code) \(stopName)"
            }
            return stopName
        }
    }
}
