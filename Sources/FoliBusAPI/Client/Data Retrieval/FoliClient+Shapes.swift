import Foundation

// MARK: - Shapes (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    /// Fetch route IDs that expose shapes from GTFS.
    /// - Returns: Array of route IDs that have at least one available shape.
    internal func fetchShapeRouteIDsFromNetwork() async throws -> [String] {
        try await dedup.performDeduplicated(.shapeRouteIds) { [self] in
            try await requestGTFS("/shapes", as: [String].self)
        }
    }

    /// Fetch shape points for one shape ID directly from GTFS.
    /// - Parameter routeId: The route identifier to fetch shapes for.
    /// - Returns: Shape points ordered by sequence.
    internal func fetchShapePointsFromNetwork(forRouteId routeId: String) async throws -> [Foli.ShapePoint] {
        try await dedup.performDeduplicated(.shapePointsForShape(routeId)) { [self] in
            let shapePointList = try await requestGTFS("/shapes/\(routeId)", as: Foli.ShapePointList.self)
            return shapePointList.shapePoints
                .enumerated()
                .map { index, shapePoint in
                    Foli.ShapePoint(
                        shapeId: shapePoint.shapeId.isEmpty ? routeId : shapePoint.shapeId,
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
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadShapeRouteIds() {
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleShapeRouteIds() {
                await refreshCacheInBackground(
                    for: .shapeRouteIds,
                    fetch: { [self] in try await fetchShapeRouteIDsFromNetwork() },
                    save: { [cache] routeIds in try await cache?.saveShapeRouteIds(routeIds) }
                )
                return staleCached
            }
            fallthrough

        case .forceRefresh:
            let routeIds = try await fetchShapeRouteIDsFromNetwork()
            try? await cache?.saveShapeRouteIds(routeIds)
            return routeIds

        case .cachedOnly:
            guard let cached = try await cache?.loadShapeRouteIds() else {
                throw Foli.APIError.noData
            }
            return cached

        case .noCache:
            return try await fetchShapeRouteIDsFromNetwork()
        }
    }

    /// Fetch shape points for one shape ID.
    /// - Parameter routeId: The route identifier to fetch shapes for.
    /// - Returns: Shape points ordered by sequence.
    func fetchShapePoints(forRouteId routeId: String) async throws -> [Foli.ShapePoint] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadShapePoints(forShape: routeId) {
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleShapePoints(forShape: routeId) {
                await refreshCacheInBackground(
                    for: .shapePointsForShape(routeId),
                    fetch: { [self] in try await fetchShapePointsFromNetwork(forRouteId: routeId) },
                    save: { [cache] shapePoints in try await cache?.saveShapePoints(shapePoints, forShape: routeId) }
                )
                return staleCached
            }
            fallthrough

        case .forceRefresh:
            let shapePoints = try await fetchShapePointsFromNetwork(forRouteId: routeId)
            try? await cache?.saveShapePoints(shapePoints, forShape: routeId)
            return shapePoints

        case .cachedOnly:
            guard let cached = try await cache?.loadShapePoints(forShape: routeId) else {
                throw Foli.APIError.noData
            }
            return cached

        case .noCache:
            return try await fetchShapePointsFromNetwork(forRouteId: routeId)
        }
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
