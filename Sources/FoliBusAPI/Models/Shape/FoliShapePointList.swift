import Foundation

// MARK: - Shape Point List Response
extension Foli {
    /// Response containing shape geometry points (GTFS shapes.txt)
    struct ShapePointList: Codable, Sendable {
        /// Ordered shape points for a specific shape.
        let shapePoints: [Foli.ShapePoint]

        /// Payload format documented by Föli (`lat`, `lon`, `traveled`).
        struct APIDocumentedShapePoint: Codable, Sendable {
            let lat: Double
            let lon: Double
            let traveled: Double?
        }

        init(shapePoints: [Foli.ShapePoint]) {
            self.shapePoints = shapePoints
        }

        /// Decodes both canonical GTFS shape-point payloads and documented Föli payloads.
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([Foli.ShapePoint].self) {
                self.shapePoints = array.sorted {
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
