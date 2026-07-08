import Foundation

// MARK: - Stop List Response
extension Foli {
    /// Response containing all known stops (GTFS stops.txt)
    struct StopList: Codable, Sendable, Equatable, Hashable {
        /// Private helper struct to decode the API response format where lat/lon are numbers
        /// and parent_station can be either Int (0) or String (station ID)
        private struct APIStopData: Decodable, Sendable {
            let stop_name: String
            let stop_code: String?
            let stop_desc: String?
            let stop_lat: Double?
            let stop_lon: Double?
            let zone_id: String?
            let stop_url: String?
            let location_type: Int?
            let parent_station: String?
            let stop_timezone: String?
            let wheelchair_boarding: Int?
            
            private enum CodingKeys: String, CodingKey {
                case stop_name, stop_code, stop_desc, stop_lat, stop_lon, zone_id
                case stop_url, location_type, parent_station, stop_timezone, wheelchair_boarding
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                stop_name = try container.decode(String.self, forKey: .stop_name)
                stop_code = try container.decodeIfPresent(String.self, forKey: .stop_code)
                stop_desc = try container.decodeIfPresent(String.self, forKey: .stop_desc)
                stop_lat = try container.decodeIfPresent(Double.self, forKey: .stop_lat)
                stop_lon = try container.decodeIfPresent(Double.self, forKey: .stop_lon)
                zone_id = try container.decodeIfPresent(String.self, forKey: .zone_id)
                stop_url = try container.decodeIfPresent(String.self, forKey: .stop_url)
                location_type = try container.decodeIfPresent(Int.self, forKey: .location_type)
                stop_timezone = try container.decodeIfPresent(String.self, forKey: .stop_timezone)
                wheelchair_boarding = try container.decodeIfPresent(Int.self, forKey: .wheelchair_boarding)
                
                // Handle parent_station which can be Int (0) or String (station ID)
                if let intValue = try? container.decode(Int.self, forKey: .parent_station) {
                    parent_station = String(intValue)
                } else {
                    parent_station = try container.decodeIfPresent(String.self, forKey: .parent_station)
                }
            }
        }

        /// Array of all stops
        let stops: [Foli.Stop]

        init(stops: [Foli.Stop]) {
            self.stops = stops
        }

        /// Helper to decode the top-level dictionary as an array of stops with IDs
        /// Handles numeric values for stop_lat and stop_lon from the API
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let dictionary = try container.decode([String: APIStopData].self)

            self.stops = dictionary.map { (id, stopData) in
                Foli.Stop(
                    id: id,
                    name: stopData.stop_name,
                    code: stopData.stop_code,
                    description: stopData.stop_desc,
                    latitude: stopData.stop_lat,
                    longitude: stopData.stop_lon,
                    zoneId: stopData.zone_id,
                    url: stopData.stop_url,
                    locationType: stopData.location_type,
                    parentStation: stopData.parent_station,
                    timezone: stopData.stop_timezone,
                    wheelchairBoarding: stopData.wheelchair_boarding
                )
            }.sorted { $0.id < $1.id }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let dictionary = Dictionary(uniqueKeysWithValues: stops.map { stop -> (String, [String: String]) in
                var data: [String: String] = ["stop_name": stop.name]
                if let code = stop.code { data["stop_code"] = code }
                if let lat = stop.latitude { data["stop_lat"] = String(lat) }
                if let lon = stop.longitude { data["stop_lon"] = String(lon) }
                if let zone = stop.zoneId { data["zone_id"] = zone }
                return (stop.id, data)
            })
            try container.encode(dictionary)
        }
    }
}
