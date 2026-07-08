import Foundation

// MARK: - Shape Point Model
/// A route geometry point from GTFS shapes.txt
public extension Foli {
    struct ShapePoint: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// GTFS `shape_id` for the polyline this point belongs to.
        public let shapeId: String
        /// Latitude in WGS-84.
        public let latitude: Double
        /// Longitude in WGS-84.
        public let longitude: Double
        /// Sequence index for ordered rendering.
        public let sequence: Int
        /// Cumulative distance traveled from route start, if present.
        public let shapeDistTraveled: Double?

        /// Creates a shape point.
        public init(
            shapeId: String,
            latitude: Double,
            longitude: Double,
            sequence: Int,
            shapeDistTraveled: Double? = nil
        ) {
            self.shapeId = shapeId
            self.latitude = latitude
            self.longitude = longitude
            self.sequence = sequence
            self.shapeDistTraveled = shapeDistTraveled
        }

        public var id: String {
            "\(shapeId)-\(sequence)"
        }

        private enum CodingKeys: String, CodingKey {
            case shapeId = "shape_id"
            case latitude = "shape_pt_lat"
            case longitude = "shape_pt_lon"
            case sequence = "shape_pt_sequence"
            case shapeDistTraveled = "shape_dist_traveled"
        }
    }
}
