import Foundation

// MARK: - Shapes (GTFS)

public extension FoliClient {
    /// Fetch route IDs that expose shapes from GTFS.
    /// - Returns: Array of route IDs that have at least one available shape.
    internal func fetchShapeRouteIDsFromNetwork() async throws -> [String] {
        try await dedup.performDeduplicated(forKey: .resource(.shapeRouteIds)) { [self] in
            try await requestGTFS("/shapes", as: [String].self)
        }
    }

    /// Fetch shape points for one shape ID directly from GTFS.
    /// - Parameter shapeId: The GTFS shape identifier to fetch points for. Obtain shape
    ///   IDs for a route via ``fetchShapeIds(forRoute:)`` or ``fetchMostCommonShapeId(forRoute:)``.
    /// - Returns: Shape points ordered by sequence.
    internal func fetchShapePointsFromNetwork(forShape shapeId: String) async throws -> [Foli.ShapePoint] {
        try await dedup.performDeduplicated(forKey: .resource(.shapePointsForShape(shapeId))) { [self] in
            let shapePointList = try await requestGTFS("/shapes/\(shapeId)", as: Foli.ShapePointList.self)
            return shapePointList.shapePoints
                .enumerated()
                .map { index, shapePoint in
                    Foli.ShapePoint(
                        shapeId: shapePoint.shapeId.isEmpty ? shapeId : shapePoint.shapeId,
                        latitude: shapePoint.latitude,
                        longitude: shapePoint.longitude,
                        sequence: shapePoint.sequence > 0 ? shapePoint.sequence : index + 1,
                        shapeDistTraveled: shapePoint.shapeDistTraveled
                    )
                }
                .sorted { $0.sequence < $1.sequence }
        }
    }

    /// Fetch all route IDs that have shape points available in GTFS.
    /// - Returns: Array of route IDs that have at least one available shape.
    func fetchShapeRouteIDs() async throws -> [String] {
        try await resolveCached(
            for: .shapeRouteIds,
            load: { [cache] in try await cache?.loadShapeRouteIds() },
            loadStale: { [cache] in try await cache?.loadStaleShapeRouteIds() },
            save: { [cache] routeIds in try await cache?.saveShapeRouteIds(routeIds) },
            fetch: { [self] in try await fetchShapeRouteIDsFromNetwork() }
        )
    }

    /// Fetch shape points for one shape ID.
    ///
    /// The GTFS shapes endpoint is keyed by shape ID, not route ID. To draw a route,
    /// first resolve its shape IDs:
    /// ```swift
    /// let shapeIds = try await client.fetchShapeIds(forRoute: route.id)
    /// let points = try await client.fetchShapePoints(forShape: shapeIds[0])
    /// ```
    /// - Parameter shapeId: The GTFS shape identifier to fetch points for.
    /// - Returns: Shape points ordered by sequence.
    func fetchShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint] {
        try await resolveCached(
            for: .shapePointsForShape(shapeId),
            load: { [cache] in try await cache?.loadShapePoints(forShape: shapeId) },
            loadStale: { [cache] in try await cache?.loadStaleShapePoints(forShape: shapeId) },
            save: { [cache] shapePoints in try await cache?.saveShapePoints(shapePoints, forShape: shapeId) },
            fetch: { [self] in try await fetchShapePointsFromNetwork(forShape: shapeId) }
        )
    }
    
    // MARK: - Shape Discovery Helpers
    
    /// Get all unique shape IDs used by a specific route.
    ///
    /// This method fetches all trips for a route and extracts the unique shape IDs.
    ///
    /// - Parameter routeId: The route identifier to fetch shape IDs for.
    /// - Returns: Array of unique shape IDs used by the route.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchShapeIds(forRoute routeId: String) async throws -> [String] {
        let trips = try await fetchTrips(forRoute: routeId)
        let shapeIds = Set(trips.compactMap { $0.shapeId })
        return Array(shapeIds).sorted()
    }
    
    /// Get the most commonly used shape ID for a specific route.
    ///
    /// This is useful when you want to display a single representative route shape
    /// on a map, as it selects the shape used by the most trips.
    ///
    /// - Parameter routeId: The route identifier to analyze.
    /// - Returns: The most frequently used shape ID, or `nil` if no shapes are found.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchMostCommonShapeId(forRoute routeId: String) async throws -> String? {
        let trips = try await fetchTrips(forRoute: routeId)
        let shapeIds = trips.compactMap { $0.shapeId }
        
        guard !shapeIds.isEmpty else { return nil }
        
        // Count occurrences of each shape ID
        let shapeCounts = Dictionary(grouping: shapeIds) { $0 }
            .mapValues { $0.count }
        
        // Return the shape ID with the highest count
        return shapeCounts.max { $0.value < $1.value }?.key
    }
}
