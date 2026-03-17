import Foundation

// MARK: - Route List Response
extension Foli {
    /// Response containing all known routes (GTFS routes.txt)
    struct RouteList: Codable, Sendable {
        /// Array of all routes
        let routes: [Foli.Route]

        init(routes: [Foli.Route]) {
            self.routes = routes
        }

        // MARK: - API Decoding Helper
        /// Helper struct to decode the API response format where route_type is a number
        struct APIRouteData: Codable, Sendable {
            let route_id: String
            let route_short_name: String
            let route_long_name: String
            let route_desc: String?
            let route_type: Int
            let route_url: String?
            let route_color: String?
            let route_text_color: String?
            let agency_id: String?
        }

        /// Helper to decode an array of route dictionaries from the API
        /// The API returns an array of routes with route_id as a field, not as dictionary keys
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let array = try container.decode([Foli.Route].self)

            self.routes = array.sorted { $0.id < $1.id }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let array = routes.map { route -> APIRouteData in
                APIRouteData(
                    route_id: route.id,
                    route_short_name: route.shortName,
                    route_long_name: route.longName,
                    route_desc: route.description,
                    route_type: route.type,
                    route_url: route.url,
                    route_color: route.colorHex,
                    route_text_color: route.textColorHex,
                    agency_id: route.agencyId
                )
            }
            try container.encode(array)
        }
    }
}
