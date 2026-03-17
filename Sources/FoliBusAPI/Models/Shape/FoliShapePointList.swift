import Foundation

// MARK: - Shape Point List Response
public extension Foli {
    /// Response containing shape geometry points (GTFS shapes.txt)
    struct ShapePointList: Codable, Sendable {
        /// Ordered shape points for a specific shape.
        public let shapePoints: [Foli.ShapePoint]

        /// Payload format documented by Föli (`lat`, `lon`, `traveled`).
        struct APIDocumentedShapePoint: Codable, Sendable {
            let lat: Double
            let lon: Double
            let traveled: Double?
        }

        public init(shapePoints: [Foli.ShapePoint]) {
            self.shapePoints = shapePoints
        }

        /// Decodes both canonical GTFS shape-point payloads and documented Föli payloads.
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([Foli.ShapePoint].self) {
                self.shapePoints = array.sorted {
                    if $0.shapeId == $1.shapeId {
                        return $0.shapePtSequence < $1.shapePtSequence
                    }
                    return $0.shapeId < $1.shapeId
                }
                return
            }

            let documentedArray = try container.decode([APIDocumentedShapePoint].self)
            self.shapePoints = documentedArray.enumerated().map { index, point in
                Foli.ShapePoint(
                    shapeId: "",
                    shapePtLat: point.lat,
                    shapePtLon: point.lon,
                    shapePtSequence: index + 1,
                    shapeDistTraveled: point.traveled
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(shapePoints)
        }
    }
}
