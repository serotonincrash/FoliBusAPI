import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Concurrency Behavior Tests")
struct ConcurrencyBehaviorTests {
    @Test("APIError wraps underlying errors while preserving the original error and being Sendable")
    func apiErrorWrapsUnderlyingErrorsWhileRemainingSendable() async throws {
        let urlError = URLError(.timedOut)
        let error = Foli.APIError.networkError(urlError)

        guard case .networkError(let wrappedError) = error else {
            Issue.record("Expected networkError case")
            return
        }

        #expect(wrappedError as? URLError == urlError)
        #expect(wrappedError.localizedDescription == urlError.localizedDescription)
        #expect(error.localizedDescription == "Network error: \(urlError.localizedDescription)")
    }

    @Test("background refresh bookkeeping is removed after a stale-while-revalidate task finishes")
    func backgroundRefreshTaskIsClearedAfterCompletion() async throws {
        let transport = MockTransport { request in
            if request.url?.absoluteString == "https://data.foli.fi/gtfs/v0" {
                return try makeJSONResponse(for: request, jsonObject: ["latest": "newer-dataset"])
            }

            return try makeDataResponse(for: request, data: Data("[]".utf8))
        }

        let cache = ControlledCache(revalidationResult: false)
        let client = FoliClient(transport: transport, cacheBehavior: .staleWhileRevalidate)
        await client.installCacheForTesting(cache)

        await client.refreshCacheInBackground(
            for: .routes,
            fetch: { ["fresh-routes"] },
            save: { routes in
                await cache.recordSavedRoutes(routes)
            }
        )

        #expect(await client.hasBackgroundRefreshTask(for: .routes))

        for _ in 0..<40 {
            if await !client.hasBackgroundRefreshTask(for: .routes) {
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }

        #expect(await !client.hasBackgroundRefreshTask(for: .routes))
        #expect(await cache.savedRoutes == [["fresh-routes"]])
    }

    @Test("CacheError is thrown when attempting to get file URL for non-cacheable resource")
    func cacheErrorThrownForNonCacheableResourceInFileURL() async throws {
        let cache = try Foli.DiskCache()
        
        do {
            _ = try await cache.fileURL(for: Foli.Resource.vehicleMonitoring)
            Issue.record("Expected fileURL to throw CacheError for vehicleMonitoring")
        } catch let error as Foli.CacheError {
            guard case .resourceNotCacheable(let resource) = error else {
                Issue.record("Expected resourceNotCacheable case, got \(error)")
                return
            }
            #expect(resource == Foli.Resource.vehicleMonitoring)
            #expect(error.localizedDescription.contains("not cacheable"))
        }
    }

    @Test("CacheError is thrown when attempting to refresh metadata for non-cacheable resource")
    func cacheErrorThrownForNonCacheableResourceInRefreshMetadata() async throws {
        let cache = try Foli.DiskCache()
        
        do {
            try await cache.refreshMetadataTimestamp(for: Foli.Resource.alerts)
            Issue.record("Expected refreshMetadataTimestamp to throw CacheError for alerts")
        } catch let error as Foli.CacheError {
            guard case .resourceNotCacheable(let resource) = error else {
                Issue.record("Expected resourceNotCacheable case, got \(error)")
                return
            }
            #expect(resource == Foli.Resource.alerts)
            #expect(error.localizedDescription.contains("Real-time data"))
        }
    }
}

private actor ControlledCache: Foli.Cache {
    let timeoutDuration: Foli.CacheTimeout = .default
    private let revalidationResult: Bool
    private(set) var savedRoutes: [[String]] = []

    init(revalidationResult: Bool) {
        self.revalidationResult = revalidationResult
    }

    var currentDatasetId: String? {
        get async throws { nil }
    }

    func loadRoutes() async throws -> [Foli.Route]? { nil }
    func saveRoutes(_ routes: [Foli.Route]) async throws {}
    func loadStops() async throws -> [Foli.Stop]? { nil }
    func saveStops(_ stops: [Foli.Stop]) async throws {}
    func loadTrips() async throws -> [Foli.Trip]? { nil }
    func saveTrips(_ trips: [Foli.Trip]) async throws {}
    func loadTrips(forRoute routeId: String) async throws -> [Foli.Trip]? { nil }
    func saveTrips(_ trips: [Foli.Trip], forRoute routeId: String) async throws {}
    func loadStopTimes() async throws -> [Foli.StopTime]? { nil }
    func saveStopTimes(_ stopTimes: [Foli.StopTime]) async throws {}
    func loadStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? { nil }
    func saveStopTimes(_ stopTimes: [Foli.StopTime], forTrip tripId: String) async throws {}
    func loadStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? { nil }
    func saveStopTimes(_ stopTimes: [Foli.StopTime], forStop stopId: String) async throws {}
    func loadCalendarDates() async throws -> [Foli.CalendarDate]? { nil }
    func saveCalendarDates(_ calendarDates: [Foli.CalendarDate]) async throws {}
    func loadAgencies() async throws -> [Foli.Agency]? { nil }
    func saveAgencies(_ agencies: [Foli.Agency]) async throws {}
    func loadCalendars() async throws -> [Foli.Calendar]? { nil }
    func saveCalendars(_ calendars: [Foli.Calendar]) async throws {}
    func loadShapeRouteIds() async throws -> [String]? { nil }
    func saveShapeRouteIds(_ routeIds: [String]) async throws {}
    func loadShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint]? { nil }
    func saveShapePoints(_ shapePoints: [Foli.ShapePoint], forShape shapeId: String) async throws {}
    func clearAllCache() async throws {}
    func clearCache(for type: Foli.Resource) async throws {}
    func hasValidCache(for type: Foli.Resource) async -> Bool { false }
    func cacheAge(for type: Foli.Resource) async -> TimeInterval? { nil }
    func currentDatasetId(for type: Foli.Resource?) async throws -> String? { nil }
    func loadStaleRoutes() async throws -> [Foli.Route]? { nil }
    func loadStaleStops() async throws -> [Foli.Stop]? { nil }
    func loadStaleTrips() async throws -> [Foli.Trip]? { nil }
    func loadStaleTrips(forRoute routeId: String) async throws -> [Foli.Trip]? { nil }
    func loadStaleStopTimes() async throws -> [Foli.StopTime]? { nil }
    func loadStaleStopTimes(forTrip tripId: String) async throws -> [Foli.StopTime]? { nil }
    func loadStaleStopTimes(forStop stopId: String) async throws -> [Foli.StopTime]? { nil }
    func loadStaleCalendarDates() async throws -> [Foli.CalendarDate]? { nil }
    func loadStaleAgencies() async throws -> [Foli.Agency]? { nil }
    func loadStaleCalendars() async throws -> [Foli.Calendar]? { nil }
    func loadStaleShapeRouteIds() async throws -> [String]? { nil }
    func loadStaleShapePoints(forShape shapeId: String) async throws -> [Foli.ShapePoint]? { nil }
    func revalidateCache(for type: Foli.Resource) async throws -> Bool { revalidationResult }

    func recordSavedRoutes(_ routes: [String]) {
        savedRoutes.append(routes)
    }
}

private extension FoliClient {
    func installCacheForTesting(_ cache: some Foli.Cache) {
        self.cache = cache
    }
}
