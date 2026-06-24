import Foundation

// MARK: - Foli.Trip Model
/// Planned GTFS trip metadata for a single service run.
///
/// A trip represents a single journey by a vehicle along a route at a specific time.
/// Trips are associated with a service calendar that determines operating days.
public extension Foli {
    struct Trip: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// The GTFS `trip_id` value — used as the stable `Identifiable` identity.
        public let tripId: String
        /// The route this trip belongs to (GTFS `route_id`).
        public let routeId: String?
        /// The service calendar this trip follows (GTFS `service_id`).
        public let serviceId: String
        /// The text displayed on the vehicle indicating the destination (GTFS `trip_headsign`).
        public let tripHeadsign: String
        /// Travel direction: 0 for one direction, 1 for the opposite (GTFS `direction_id`).
        public let directionId: Int
        /// Block identifier for vehicle interlining (GTFS `block_id`).
        public let blockId: String
        /// Shape identifier for route geometry (GTFS `shape_id`).
        public let shapeId: String
        /// Wheelchair accessibility: 0 = no info, 1 = accessible, 2 = not accessible (GTFS `wheelchair_accessible`).
        public let wheelchairAccessible: Int
        /// Bike policy: 0 = no info, 1 = allowed, 2 = not allowed (GTFS `bikes_allowed`).
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
