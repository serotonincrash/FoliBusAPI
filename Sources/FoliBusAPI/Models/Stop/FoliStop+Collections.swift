import Foundation

// MARK: - Stop Collection Helpers

public extension Collection where Element == Foli.Stop {
    /// Returns the stops sorted by name, ascending.
    func sortedByName() -> [Foli.Stop] {
        sorted { $0.name < $1.name }
    }

    /// Returns the stops sorted by ID, ascending.
    func sortedByID() -> [Foli.Stop] {
        sorted { $0.id < $1.id }
    }

    /// Returns the stops whose name or ID contains the given query string (case-insensitive).
    /// - Parameter query: The search string to match against stop names and IDs.
    /// - Returns: Matching stops sorted by name.
    func search(_ query: String) -> [Foli.Stop] {
        filter { stop in
            stop.name.localizedCaseInsensitiveContains(query) || stop.id.contains(query)
        }.sortedByName()
    }
    
    // MARK: - Geographic Filtering
    
    /// Returns stops grouped by zone ID.
    /// - Returns: Dictionary mapping zone IDs to arrays of stops in that zone.
    func groupedByZone() -> [String?: [Foli.Stop]] {
        Dictionary(grouping: self) { $0.zoneId }
    }
    
    /// Returns only stops that have valid location coordinates.
    /// - Returns: Array of stops with non-nil latitude and longitude.
    func withLocation() -> [Foli.Stop] {
        filter { $0.hasLocation }
    }
    
    /// Returns stops within a specified geographic bounding box.
    ///
    /// - Parameters:
    ///   - latRange: The latitude range (e.g., 60.4...60.5).
    ///   - lonRange: The longitude range (e.g., 22.2...22.3).
    /// - Returns: Array of stops within the specified bounds.
    func within(latRange: ClosedRange<Double>, lonRange: ClosedRange<Double>) -> [Foli.Stop] {
        filter { stop in
            guard let lat = stop.latitude, let lon = stop.longitude else { return false }
            return latRange.contains(lat) && lonRange.contains(lon)
        }
    }
    
    /// Returns stops sorted by distance from a given coordinate.
    ///
    /// Uses simple Euclidean distance calculation. For more accurate distance calculations
    /// over larger areas, consider using the Haversine formula.
    ///
    /// - Parameter coordinate: The reference coordinate to measure distance from.
    /// - Returns: Array of stops sorted by distance (nearest first).
    func sortedByDistance(from coordinate: Foli.Coordinate) -> [Foli.Stop] {
        compactMap { stop -> (stop: Foli.Stop, distance: Double)? in
            guard let lat = stop.latitude, let lon = stop.longitude else { return nil }
            let distance = sqrt(
                pow(lat - coordinate.latitude, 2) + pow(lon - coordinate.longitude, 2)
            )
            return (stop, distance)
        }
        .sorted { $0.distance < $1.distance }
        .map { $0.stop }
    }
    
    /// Returns the nearest stop to a given coordinate.
    ///
    /// - Parameter coordinate: The reference coordinate.
    /// - Returns: The nearest stop, or `nil` if no stops have valid locations.
    func nearest(to coordinate: Foli.Coordinate) -> Foli.Stop? {
        sortedByDistance(from: coordinate).first
    }
}
