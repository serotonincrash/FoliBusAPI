import Foundation

// MARK: - Route List Response
extension Foli {
    /// Response containing all known routes (GTFS routes.txt)
    struct RouteList: Codable, Sendable, Equatable, Hashable {
        /// Array of all routes
        let routes: [Foli.Route]

        init(routes: [Foli.Route]) {
            self.routes = routes
        }

        /// Helper to decode an array of route dictionaries from the API
        /// The API returns an array of routes with route_id as a field, not as dictionary keys
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let array = try container.decode([Foli.Route].self)

            self.routes = array.sorted { $0.id < $1.id }
        }

        /// Encodes the bare route array (matching the API's wire format), not a
        /// `{"routes": …}` wrapper — `Foli.Route`'s CodingKeys handle the snake_case keys.
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(routes)
        }
    }
}
