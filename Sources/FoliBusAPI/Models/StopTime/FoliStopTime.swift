import Foundation

public extension Foli {
    /// Planned timetable entry for a trip stop or stop-specific departure listing.
    struct StopTime: Codable, Sendable, Identifiable, Equatable {
        public let tripId: String?
        public let arrivalTime: String
        public let departureTime: String
        public let stopId: String?
        public let stopSequence: Int
        public let stopHeadsign: String?
        public let pickupType: Int?
        public let dropOffType: Int?
        public let shapeDistTraveled: Double?
        public let timepoint: Int?

        /// A deterministic stable identifier derived from `tripId` and `stopSequence`.
        public var id: String { "\(tripId ?? ""):\(stopSequence)" }

        /// Creates a stop-time value using GTFS stop_times fields.
        /// - Parameters:
        ///   - tripId: Optional GTFS `trip_id` value.
        ///   - arrivalTime: The GTFS `arrival_time` value.
        ///   - departureTime: The GTFS `departure_time` value.
        ///   - stopId: Optional GTFS `stop_id` value.
        ///   - stopSequence: The GTFS `stop_sequence` value.
        ///   - stopHeadsign: Optional GTFS `stop_headsign` value.
        ///   - pickupType: Optional GTFS `pickup_type` value.
        ///   - dropOffType: Optional GTFS `drop_off_type` value.
        ///   - shapeDistTraveled: Optional GTFS `shape_dist_traveled` value.
        ///   - timepoint: Optional GTFS `timepoint` value.
        public init(
            tripId: String? = nil,
            arrivalTime: String,
            departureTime: String,
            stopId: String? = nil,
            stopSequence: Int,
            stopHeadsign: String? = nil,
            pickupType: Int? = nil,
            dropOffType: Int? = nil,
            shapeDistTraveled: Double? = nil,
            timepoint: Int? = nil
        ) {
            self.tripId = tripId
            self.arrivalTime = arrivalTime
            self.departureTime = departureTime
            self.stopId = stopId
            self.stopSequence = stopSequence
            self.stopHeadsign = stopHeadsign
            self.pickupType = pickupType
            self.dropOffType = dropOffType
            self.shapeDistTraveled = shapeDistTraveled
            self.timepoint = timepoint
        }

        public enum CodingKeys: String, CodingKey {
            case tripId = "trip_id"
            case arrivalTime = "arrival_time"
            case departureTime = "departure_time"
            case stopId = "stop_id"
            case stopSequence = "stop_sequence"
            case stopHeadsign = "stop_headsign"
            case pickupType = "pickup_type"
            case dropOffType = "drop_off_type"
            case shapeDistTraveled = "shape_dist_traveled"
            case timepoint = "timepoint"
        }
    }
}
