import Foundation

public extension Foli {
    /// Planned GTFS trip metadata for a single service run.
    struct Trip: Codable, Sendable, Identifiable, Equatable {
        /// The GTFS `trip_id` value — used as the stable `Identifiable` identity.
        public let tripId: String
        public let routeId: String?
        public let serviceId: String
        public let tripHeadsign: String
        public let directionId: Int
        public let blockId: String
        public let shapeId: String
        public let wheelchairAccessible: Int
        public let bikesAllowed: Int?

        /// The stable identifier for this trip (the GTFS `trip_id`).
        public var id: String { tripId }

        /// Creates a trip value using GTFS trip fields.
        /// - Parameters:
        ///   - tripId: The GTFS `trip_id` value.
        ///   - routeId: Optional GTFS `route_id` value.
        ///   - serviceId: The GTFS `service_id` value.
        ///   - tripHeadsign: The GTFS `trip_headsign` value.
        ///   - directionId: The GTFS `direction_id` value.
        ///   - blockId: The GTFS `block_id` value.
        ///   - shapeId: The GTFS `shape_id` value.
        ///   - wheelchairAccessible: The GTFS `wheelchair_accessible` value.
        ///   - bikesAllowed: Optional GTFS `bikes_allowed` value.
        public init(
            tripId: String,
            routeId: String? = nil,
            serviceId: String,
            tripHeadsign: String,
            directionId: Int,
            blockId: String,
            shapeId: String,
            wheelchairAccessible: Int,
            bikesAllowed: Int? = nil
        ) {
            self.tripId = tripId
            self.routeId = routeId
            self.serviceId = serviceId
            self.tripHeadsign = tripHeadsign
            self.directionId = directionId
            self.blockId = blockId
            self.shapeId = shapeId
            self.wheelchairAccessible = wheelchairAccessible
            self.bikesAllowed = bikesAllowed
        }

        private enum CodingKeys: String, CodingKey {
            case tripId = "trip_id"
            case routeId = "route_id"
            case serviceId = "service_id"
            case tripHeadsign = "trip_headsign"
            case directionId = "direction_id"
            case blockId = "block_id"
            case shapeId = "shape_id"
            case wheelchairAccessible = "wheelchair_accessible"
            case bikesAllowed = "bikes_allowed"
        }
    }
}
