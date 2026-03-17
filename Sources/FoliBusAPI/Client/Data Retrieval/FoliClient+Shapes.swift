import Foundation

// MARK: - Shapes (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    /// Fetch route IDs that expose shapes from GTFS.
    /// - Returns: Array of route IDs that have at least one available shape.
    func fetchShapeRouteIDsFromNetwork() async throws -> [String] {
        try await performDeduplicated(.shapeRouteIds) { [self] in
            try await requestGTFS("/shapes", as: [String].self)
        }
    }

    /// Fetch shape points for one shape ID directly from GTFS.
    /// - Parameter routeId: The route identifier to fetch shapes for.
    /// - Returns: Shape points ordered by sequence.
    func fetchShapePointsFromNetwork(forRouteId routeId: String) async throws -> [Foli.ShapePoint] {
        try await performDeduplicated(.shapePointsForShape(routeId)) { [self] in
            let shapePointList = try await requestGTFS("/shapes/\(routeId)", as: Foli.ShapePointList.self)
            return shapePointList.shapePoints
                .enumerated()
                .map { index, shapePoint in
                    Foli.ShapePoint(
                        shapeId: shapePoint.shapeId.isEmpty ? routeId : shapePoint.shapeId,
                        shapePtLat: shapePoint.shapePtLat,
                        shapePtLon: shapePoint.shapePtLon,
                        shapePtSequence: shapePoint.shapePtSequence > 0 ? shapePoint.shapePtSequence : index + 1,
                        shapeDistTraveled: shapePoint.shapeDistTraveled
                    )
                }
                .sorted { $0.shapePtSequence < $1.shapePtSequence }
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
                refreshCacheInBackground(
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
                refreshCacheInBackground(
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
}
