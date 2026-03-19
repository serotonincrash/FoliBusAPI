import Foundation

// MARK: - Shapes API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    /// Fetch route IDs that have shape points available.
    /// - Returns: Array of route IDs.
    func fetchShapeRouteIDs() async throws -> [String] {
        try await client.fetchShapeRouteIDs()
    }

    /// Fetch shape points for a specific shape ID.
    /// - Parameter routeId: The route identifier to fetch shapes for.
    /// - Returns: Array of shape points ordered by sequence.
    func fetchShapePoints(forRouteId routeId: String) async throws -> [Foli.ShapePoint] {
        try await client.fetchShapePoints(forRouteId: routeId)
    }
}
