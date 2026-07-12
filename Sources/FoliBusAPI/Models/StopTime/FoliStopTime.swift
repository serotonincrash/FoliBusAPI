import Foundation

// MARK: - Foli.StopTime Model
/// Planned timetable entry for a trip stop or stop-specific departure listing.
///
/// - SeeAlso: ``Foli/Trip``, ``Foli/Stop``
///
/// Stop times define when a vehicle arrives at and departs from individual stops during a trip.
/// Times are in HH:MM:SS format and may exceed 24:00:00 for trips crossing midnight.
public extension Foli {
    struct StopTime: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// The trip this stop time belongs to (GTFS `trip_id`).
        public let tripId: String?
        /// Scheduled arrival time in HH:MM:SS format (GTFS `arrival_time`).
        public let arrivalTime: String
        /// Scheduled departure time in HH:MM:SS format (GTFS `departure_time`).
        public let departureTime: String
        /// The stop where this arrival/departure occurs (GTFS `stop_id`).
        public let stopId: String?
        /// Order of this stop in the trip sequence, starting from 1 (GTFS `stop_sequence`).
        public let stopSequence: Int
        /// Override headsign for this stop only (GTFS `stop_headsign`).
        public let stopHeadsign: String?
        /// Pickup availability: 0 = regular, 1 = none, 2 = phone agency, 3 = coordinate with driver (GTFS `pickup_type`).
        public let pickupType: Int?
        /// Drop-off availability: 0 = regular, 1 = none, 2 = phone agency, 3 = coordinate with driver (GTFS `drop_off_type`).
        public let dropOffType: Int?
        /// Distance traveled along shape from first stop to this stop in meters (GTFS `shape_dist_traveled`).
        public let shapeDistTraveled: Double?
        /// Whether times are exact (1) or approximate (0) (GTFS `timepoint`).
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

        private enum CodingKeys: String, CodingKey {
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
