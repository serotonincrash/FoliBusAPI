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

// MARK: - Stop List Response
/// Response containing all known stops (GTFS stops.txt)
public struct FoliStopList: Codable {
    
    /// Private helper struct to decode the API response format where lat/lon are numbers
    private struct APIStopData: Decodable {
        let stop_name: String
        let stop_code: String?
        let stop_lat: Double?
        let stop_lon: Double?
        let zone_id: String?
    }
    
    /// Array of all stops
    public let stops: [Foli.Stop]
    
    public init(stops: [Foli.Stop]) {
        self.stops = stops
    }
    
    /// Helper to decode the top-level dictionary as an array of stops with IDs
    /// Handles numeric values for stop_lat and stop_lon from the API
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: APIStopData].self)
        
        self.stops = dictionary.map { (id, stopData) in
            Foli.Stop(
                id: id,
                stopName: stopData.stop_name,
                stopCode: stopData.stop_code,
                stopLat: stopData.stop_lat,
                stopLon: stopData.stop_lon,
                zoneId: stopData.zone_id
            )
        }.sorted { $0.id < $1.id }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let dictionary = Dictionary(uniqueKeysWithValues: stops.map { stop -> (String, [String: String]) in
            var data: [String: String] = ["stop_name": stop.stopName]
            if let code = stop.stopCode { data["stop_code"] = code }
            if let lat = stop.stopLat { data["stop_lat"] = String(lat) }
            if let lon = stop.stopLon { data["stop_lon"] = String(lon) }
            if let zone = stop.zoneId { data["zone_id"] = zone }
            return (stop.id, data)
        })
        try container.encode(dictionary)
    }
}
