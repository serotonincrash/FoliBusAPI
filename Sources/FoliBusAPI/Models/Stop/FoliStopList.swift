import Foundation

// MARK: - Stop List Response
public extension Foli {
    /// Response containing all known stops (GTFS stops.txt)
    struct StopList: Codable, Sendable {
        /// Private helper struct to decode the API response format where lat/lon are numbers
        private struct APIStopData: Decodable, Sendable {
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
}
