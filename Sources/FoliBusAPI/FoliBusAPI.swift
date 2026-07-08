import Foundation

/// Convenience facade for common Föli API operations.
///
/// Use ``FoliBusAPI`` when you want simple static entry points backed by a configurable
/// client provider. For more control over transport, caching, or environment
/// integration, use ``FoliClient`` directly.
///
/// The facade's backing provider can be replaced at app launch via ``configure(_:)``
/// and reset between test cases via ``reset()``.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public final class FoliBusAPI {
    /// Internal actor that protects the facade's provider from concurrent access.
    private actor ProviderBox {
        var provider: any FoliClientProviding
        init(_ provider: any FoliClientProviding) { self.provider = provider }
        func set(_ provider: any FoliClientProviding) { self.provider = provider }
        func client() -> FoliClient { provider.client() }
    }

    /// The provider backing the static convenience methods, protected by an actor
    /// to make concurrent reads and writes provably safe.
    ///
    /// Defaults to a ``DefaultFoliClientProvider`` with ``FoliClientConfiguration/default``.
    /// Replace it at app launch via ``configure(_:)`` to route the convenience API through
    /// a custom provider (e.g., one using a test transport or a specific cache configuration).
    /// Reset it between test cases via ``reset()``.
    private static let provider = ProviderBox(DefaultFoliClientProvider())

    /// Configures the provider backing the static convenience methods.
    ///
    /// Call this at app launch to route ``FoliBusAPI`` static methods through a custom
    /// provider. This replaces the previous provider entirely.
    ///
    /// - Parameter provider: The provider to use for all subsequent static fetch calls.
    public static func configure(_ provider: any FoliClientProviding) async {
        await Self.provider.set(provider)
    }

    /// Resets the provider to a fresh ``DefaultFoliClientProvider`` with default configuration.
    ///
    /// Call this between test cases to ensure the static convenience methods don't share
    /// cache state across tests.
    public static func reset() async {
        await Self.provider.set(DefaultFoliClientProvider())
    }

    private static func defaultClient() async -> FoliClient {
        await provider.client()
    }
    
    // MARK: - Convenience Methods - Real-Time Data
    
    /// Fetch all active alerts (messages and cancellations).
    ///
    /// - Returns: Alerts response containing messages, cancellations, and special alerts.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchAlerts() async throws -> Foli.AlertsResponse {
        let client = await defaultClient()
        return try await client.fetchAlerts()
    }
    
    /// Fetch only informational alert messages.
    ///
    /// - Returns: Array of alert messages.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchAlertMessages() async throws -> [Foli.Alert] {
        let client = await defaultClient()
        return try await client.fetchAlertMessages()
    }
    
    /// Fetch only trip cancellations.
    ///
    /// - Returns: Array of trip cancellations.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchCancellations() async throws -> [Foli.TripCancellation] {
        let client = await defaultClient()
        return try await client.fetchCancellations()
    }
    
    /// Fetch alert category descriptions.
    ///
    /// - Returns: Array of alert categories.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchAlertCategories() async throws -> [Foli.AlertCategory] {
        let client = await defaultClient()
        return try await client.fetchAlertCategories()
    }
    
    /// Fetch all current vehicle locations from the SIRI Vehicle Monitoring (VM) endpoint.
    ///
    /// - Returns: Array of vehicle locations.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    ///
    /// - Note: The VM endpoint returns a large response. Minimum polling interval: 3 seconds.
    public static func fetchVehicleLocations() async throws -> [Foli.VehicleLocation] {
        let client = await defaultClient()
        return try await client.fetchVehicleLocations()
    }
    
    /// Fetch vehicle locations filtered by line reference.
    ///
    /// - Parameter lineRef: The line reference to filter by (e.g., "14", "2A").
    /// - Returns: Array of vehicle locations for the specified line.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    public static func fetchVehicleLocations(for lineRef: String) async throws -> [Foli.VehicleLocation] {
        let client = await defaultClient()
        return try await client.fetchVehicleLocations(for: lineRef)
    }
    
    /// Fetch vehicle locations for multiple line references.
    ///
    /// - Parameter lineRefs: Array of line references to filter by.
    /// - Returns: Array of vehicle locations matching any of the specified lines.
    /// - Throws: `Foli.APIError` if the request fails or the server returns an error status.
    public static func fetchVehicleLocations(for lineRefs: [String]) async throws -> [Foli.VehicleLocation] {
        let client = await defaultClient()
        return try await client.fetchVehicleLocations(for: lineRefs)
    }
    
    /// Fetch real-time arrival data for a stop identified by string ID.
    /// - Parameter stopId: The stop ID to monitor.
    /// - Returns: Array of vehicle arrivals.
    public static func fetchArrivals(for stopId: String) async throws -> [Foli.Arrival] {
        let client = await defaultClient()
        return try await client.fetchArrivals(for: stopId)
    }
    
    /// Fetch real-time arrival data for a specific stop model.
    /// - Parameter stop: The stop to monitor.
    /// - Returns: Array of vehicle arrivals.
    public static func fetchArrivals(for stop: Foli.Stop) async throws -> [Foli.Arrival] {
        let client = await defaultClient()
        return try await client.fetchArrivals(for: stop.id)
    }
    
    // MARK: - Convenience Methods - Stops
    
    /// Fetch the complete list of stops
    /// - Returns: Array of all stops
    public static func fetchStops() async throws -> [Foli.Stop] {
        let client = await defaultClient()
        return try await client.fetchStops()
    }
    
    // MARK: - Convenience Methods - Routes (GTFS)
    
    /// Fetch the complete list of all routes from GTFS
    /// - Returns: Array of all routes
    public static func fetchRoutes() async throws -> [Foli.Route] {
        let client = await defaultClient()
        return try await client.fetchRoutes()
    }
    
    /// Fetch a specific route by its ID
    /// - Parameter routeId: The ID of the route to fetch
    /// - Returns: The route if found
    public static func fetchRoute(byId routeId: String) async throws -> Foli.Route? {
        let client = await defaultClient()
        return try await client.route(for: routeId)
    }
    
    /// Fetch routes that match a given line reference (e.g., "15")
    /// - Parameter lineRef: The line reference to search for
    /// - Returns: Array of matching routes
    public static func fetchRoutes(byLineRef lineRef: String) async throws -> [Foli.Route] {
        let client = await defaultClient()
        return try await client.fetchRoutes(for: lineRef)
    }
    
    /// Fetch routes of a specific type
    /// - Parameter routeType: The GTFS route type (0=Tram, 3=Bus, etc.)
    /// - Returns: Array of routes matching the type
    public static func fetchRoutes(ofType routeType: Int) async throws -> [Foli.Route] {
        let client = await defaultClient()
        let allRoutes = try await client.fetchRoutes()
        return allRoutes.filter { $0.type == routeType }
    }
    
    /// Fetch only bus routes
    /// - Returns: Array of bus routes
    public static func fetchBusRoutes() async throws -> [Foli.Route] {
        return try await fetchRoutes(ofType: 3)
    }
    
    /// Fetch only tram routes
    /// - Returns: Array of tram routes
    public static func fetchTramRoutes() async throws -> [Foli.Route] {
        return try await fetchRoutes(ofType: 0)
    }
    
    // MARK: - Convenience Methods - Calendar Dates (GTFS)
    
    /// Fetch all calendar date exceptions from GTFS
    /// - Returns: Array of calendar date exceptions
    public static func fetchCalendarDates() async throws -> [Foli.CalendarDate] {
        let client = await defaultClient()
        return try await client.fetchCalendarDates()
    }
    
    // MARK: - Convenience Methods - Agencies (GTFS)
    
    /// Fetch all agencies from GTFS
    /// - Returns: Array of all agencies
    public static func fetchAgencies() async throws -> [Foli.Agency] {
        let client = await defaultClient()
        return try await client.fetchAgencies()
    }
    
    /// Fetch a specific agency by its ID
    /// - Parameter agencyId: The ID of the agency to fetch
    /// - Returns: The agency if found
    public static func fetchAgency(byId agencyId: String) async throws -> Foli.Agency? {
        let client = await defaultClient()
        return try await client.agency(for: agencyId)
    }
    
    // MARK: - Convenience Methods - Calendars (GTFS)
    
    /// Fetch all calendars from GTFS
    /// - Returns: Array of all calendars
    public static func fetchCalendars() async throws -> [Foli.Calendar] {
        let client = await defaultClient()
        return try await client.fetchCalendars()
    }
    
    /// Fetch a specific calendar by its service ID
    /// - Parameter serviceId: The service ID of the calendar to fetch
    /// - Returns: The calendar if found
    public static func fetchCalendar(forServiceId serviceId: String) async throws -> Foli.Calendar? {
        let client = await defaultClient()
        return try await client.fetchCalendar(forServiceId: serviceId)
    }
    
    // MARK: - Convenience Methods - Trips (GTFS)
    
    /// Fetch all trips from GTFS
    /// - Returns: Array of all trips
    public static func fetchTrips() async throws -> [Foli.Trip] {
        let client = await defaultClient()
        return try await client.fetchTrips()
    }
    
    /// Fetch trips for a specific route
    /// - Parameter routeId: The ID of the route to fetch trips for
    /// - Returns: Array of trips for the specified route
    public static func fetchTrips(forRoute routeId: String) async throws -> [Foli.Trip] {
        let client = await defaultClient()
        return try await client.fetchTrips(forRoute: routeId)
    }
    
    /// Fetch a specific trip by its ID
    /// - Parameter tripId: The ID of the trip to fetch
    /// - Returns: The trip if found
    public static func fetchTrip(byId tripId: String) async throws -> Foli.Trip? {
        let client = await defaultClient()
        return try await client.trip(for: tripId)
    }
    
    // MARK: - Convenience Methods - Stop Times (GTFS)
    
    /// Fetch all stop times from GTFS
    /// - Returns: Array of all stop times
    /// - Note: Not recommended for general use due to the large dataset size
    public static func fetchStopTimes() async throws -> [Foli.StopTime] {
        let client = await defaultClient()
        return try await client.fetchStopTimes()
    }
    
    /// Fetch stop times for a specific trip
    /// - Parameter tripId: The ID of the trip to fetch stop times for
    /// - Returns: Array of stop times for the specified trip
    public static func fetchStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime] {
        let client = await defaultClient()
        return try await client.fetchStopTimes(forTrip: tripId)
    }
    
    /// Fetch stop times for a specific stop
    /// - Parameter stopId: The ID of the stop to fetch stop times for
    /// - Returns: Array of stop times for the specified stop
    public static func fetchStopTimes(forStop stopId: String) async throws -> [Foli.StopTime] {
        let client = await defaultClient()
        return try await client.fetchStopTimes(forStop: stopId)
    }
    
    // MARK: - Convenience Methods - Shapes (GTFS)
    
    /// Fetch all route IDs that have shape points available
    /// - Returns: Array of route IDs that have at least one available shape
    public static func fetchShapeRouteIDs() async throws -> [String] {
        let client = await defaultClient()
        return try await client.fetchShapeRouteIDs()
    }
    
    /// Fetch shape points for a specific route
    /// - Parameter routeId: The route identifier to fetch shapes for
    /// - Returns: Shape points ordered by sequence
    public static func fetchShapePoints(forRouteId routeId: String) async throws -> [Foli.ShapePoint] {
        let client = await defaultClient()
        return try await client.fetchShapePoints(forRoute: routeId)
    }
    
    // MARK: - Convenience Methods - GeoJSON
    
    /// Fetch available GeoJSON map layers.
    ///
    /// - Returns: Array of available map layers.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchGeoJSONLayers() async throws -> [Foli.GeoJSONLayer] {
        let client = await defaultClient()
        return try await client.fetchGeoJSONLayers()
    }
    
    /// Fetch all points of interest.
    ///
    /// - Returns: GeoJSON feature collection of all POIs.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchPointsOfInterest() async throws -> Foli.FeatureCollection {
        let client = await defaultClient()
        return try await client.fetchPointsOfInterest()
    }
    
    /// Fetch points of interest by category.
    ///
    /// - Parameter category: Category name.
    /// - Returns: GeoJSON feature collection.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchPointsOfInterest(category: String) async throws -> Foli.FeatureCollection {
        let client = await defaultClient()
        return try await client.fetchPointsOfInterest(inCategory: category)
    }
    
    /// Fetch Föli service area boundaries.
    ///
    /// - Parameters:
    ///   - resolution: Boundary resolution (default: normal).
    ///   - format: Output format (default: multiPolygon).
    /// - Returns: GeoJSON feature collection with boundary geometry.
    /// - Throws: `Foli.APIError` if the request fails.
    public static func fetchServiceBounds(resolution: FoliClient.BoundsResolution = .normal, format: FoliClient.BoundsFormat = .multiPolygon) async throws -> Foli.FeatureCollection {
        let client = await defaultClient()
        return try await client.fetchServiceBounds(resolution: resolution, format: format)
    }
}
