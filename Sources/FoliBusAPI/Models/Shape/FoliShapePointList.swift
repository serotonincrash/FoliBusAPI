import Foundation

// MARK: - Shape Point List Response
extension Foli {
    /// Response containing shape geometry points (GTFS shapes.txt)
    struct ShapePointList: Codable, Sendable, Equatable, Hashable {
        /// Ordered shape points for a specific shape.
        let shapePoints: [Foli.ShapePoint]

        /// Payload format documented by Föli (`lat`, `lon`, `traveled`).
        struct APIDocumentedShapePoint: Codable, Sendable {
            let lat: Double
            let lon: Double
            let traveled: Double?
        }

        /// Canonical GTFS shape-point payload with `shape_pt_sequence` decode-optional.
        ///
        /// GTFS explicitly allows `0` as a legitimate first sequence number. Making
        /// `sequence` decode-optional (rather than defaulting missing/zero values the
        /// same way) lets us distinguish "the field was absent" from "the field is
        /// legitimately 0" — only the former should be back-filled from the point's
        /// array index, since collapsing both cases would collide a real sequence-1
        /// point's id (`"\(shapeId)-1"`) with a renumbered sequence-0 point.
        private struct RawShapePoint: Codable, Sendable {
            let shapeId: String
            let latitude: Double
            let longitude: Double
            let sequence: Int?
            let shapeDistTraveled: Double?

            private enum CodingKeys: String, CodingKey {
                case shapeId = "shape_id"
                case latitude = "shape_pt_lat"
                case longitude = "shape_pt_lon"
                case sequence = "shape_pt_sequence"
                case shapeDistTraveled = "shape_dist_traveled"
            }
        }

        init(shapePoints: [Foli.ShapePoint]) {
            self.shapePoints = shapePoints
        }

        /// Decodes both canonical GTFS shape-point payloads and documented Föli payloads.
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([RawShapePoint].self) {
                let points = array.enumerated().map { index, point in
                    Foli.ShapePoint(
                        shapeId: point.shapeId,
                        latitude: point.latitude,
                        longitude: point.longitude,
                        sequence: point.sequence ?? index + 1,
                        shapeDistTraveled: point.shapeDistTraveled
                    )
                }
                self.shapePoints = points.sorted {
                    if $0.shapeId == $1.shapeId {
                        return $0.sequence < $1.sequence
                    }
                    return $0.shapeId < $1.shapeId
                }
                return
            }

            let documentedArray = try container.decode([APIDocumentedShapePoint].self)
            self.shapePoints = documentedArray.enumerated().map { index, point in
                Foli.ShapePoint(
                    shapeId: "",
                    latitude: point.lat,
                    longitude: point.lon,
                    sequence: index + 1,
                    shapeDistTraveled: point.traveled
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(shapePoints)
        }
    }
}
