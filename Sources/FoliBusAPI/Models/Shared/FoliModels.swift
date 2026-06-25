import Foundation
import CoreLocation

// MARK: - Namespace for Foli Data Models
/// Namespace containing the package's data models, cache types, and shared helper types.
public enum Foli {}

// MARK: - Coordinate Type
public extension Foli {
    /// A lightweight, `Sendable` coordinate value used throughout the package's models.
    ///
    /// This mirrors the shape of CoreLocation's coordinate type while remaining safe to
    /// move across concurrency domains. Convert to CoreLocation's type via ``toCLCoordinate()``.
    struct Coordinate: Codable, Sendable, Equatable, Hashable {
        public let latitude: Double
        public let longitude: Double

        /// Creates a coordinate value.
        /// - Parameters:
        ///   - latitude: The latitude component in degrees.
        ///   - longitude: The longitude component in degrees.
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        /// Converts this value into CoreLocation's `CLLocationCoordinate2D`.
        /// - Returns: A CoreLocation coordinate with the same latitude and longitude.
        public func toCLCoordinate() -> CoreLocation.CLLocationCoordinate2D {
            return CoreLocation.CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

