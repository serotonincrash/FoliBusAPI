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
    
    // MARK: - Shape Discovery Helpers
    
    /// Get all unique shape IDs used by a specific route.
    /// - Parameter routeId: The route identifier to fetch shape IDs for.
    /// - Returns: Array of unique shape IDs used by the route.
    func fetchShapeIds(forRoute routeId: String) async throws -> [String] {
        try await client.fetchShapeIds(forRoute: routeId)
    }
    
    /// Get the most commonly used shape ID for a specific route.
    /// - Parameter routeId: The route identifier to analyze.
    /// - Returns: The most frequently used shape ID, or `nil` if no shapes are found.
    func fetchMostCommonShapeId(forRoute routeId: String) async throws -> String? {
        try await client.fetchMostCommonShapeId(forRoute: routeId)
    }
}
