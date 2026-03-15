import Foundation

// MARK: - Shape Point Model
/// A route geometry point from GTFS shapes.txt
public extension Foli {
    struct ShapePoint: Codable, Sendable, Identifiable, Equatable {
        /// GTFS `shape_id` for the polyline this point belongs to.
        public let shapeId: String
        /// Latitude in WGS-84.
        public let shapePtLat: Double
        /// Longitude in WGS-84.
        public let shapePtLon: Double
        /// Sequence index for ordered rendering.
        public let shapePtSequence: Int
        /// Cumulative distance traveled from route start, if present.
        public let shapeDistTraveled: Double?

        /// Creates a shape point.
        public init(
            shapeId: String,
            shapePtLat: Double,
            shapePtLon: Double,
            shapePtSequence: Int,
            shapeDistTraveled: Double? = nil
        ) {
            self.shapeId = shapeId
            self.shapePtLat = shapePtLat
            self.shapePtLon = shapePtLon
            self.shapePtSequence = shapePtSequence
            self.shapeDistTraveled = shapeDistTraveled
        }

        public var id: String {
            "\(shapeId)-\(shapePtSequence)"
        }

        enum CodingKeys: String, CodingKey {
            case shapeId = "shape_id"
            case shapePtLat = "shape_pt_lat"
            case shapePtLon = "shape_pt_lon"
            case shapePtSequence = "shape_pt_sequence"
            case shapeDistTraveled = "shape_dist_traveled"
        }
    }
}
