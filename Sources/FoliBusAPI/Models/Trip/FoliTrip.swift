import Foundation

public extension Foli {
    /// Planned GTFS trip metadata for a single service run.
    struct Trip: Codable, Sendable, Identifiable, Equatable {
        public let id = UUID()
        public let routeId: String?
        public let serviceId: String
        public let tripId: String?
        public let tripHeadsign: String
        public let directionId: Int
        public let blockId: String
        public let shapeId: String
        public let wheelchairAccessible: Int
        public let bikesAllowed: Int?

        /// Creates a trip value using GTFS trip fields.
        /// - Parameters:
        ///   - routeId: Optional GTFS `route_id` value.
        ///   - serviceId: The GTFS `service_id` value.
        ///   - tripId: Optional GTFS `trip_id` value.
        ///   - tripHeadsign: The GTFS `trip_headsign` value.
        ///   - directionId: The GTFS `direction_id` value.
        ///   - blockId: The GTFS `block_id` value.
        ///   - shapeId: The GTFS `shape_id` value.
        ///   - wheelchairAccessible: The GTFS `wheelchair_accessible` value.
        ///   - bikesAllowed: Optional GTFS `bikes_allowed` value.
        public init(
            routeId: String? = nil,
            serviceId: String,
            tripId: String? = nil,
            tripHeadsign: String,
            directionId: Int,
            blockId: String,
            shapeId: String,
            wheelchairAccessible: Int,
            bikesAllowed: Int? = nil
        ) {
            self.routeId = routeId
            self.serviceId = serviceId
            self.tripId = tripId
            self.tripHeadsign = tripHeadsign
            self.directionId = directionId
            self.blockId = blockId
            self.shapeId = shapeId
            self.wheelchairAccessible = wheelchairAccessible
            self.bikesAllowed = bikesAllowed
        }

        public enum CodingKeys: String, CodingKey {
            case routeId = "route_id"
            case serviceId = "service_id"
            case tripId = "trip_id"
            case tripHeadsign = "trip_headsign"
            case directionId = "direction_id"
            case blockId = "block_id"
            case shapeId = "shape_id"
            case wheelchairAccessible = "wheelchair_accessible"
            case bikesAllowed = "bikes_allowed"
        }
    }
}
