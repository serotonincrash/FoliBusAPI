import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Concurrency Behavior Tests")
struct ConcurrencyBehaviorTests {
    @Test("APIError wraps underlying errors while preserving the original error and being Sendable")
    func apiErrorWrapsUnderlyingErrorsWhileRemainingSendable() async throws {
        let urlError = URLError(.timedOut)
        let error = Foli.APIError.networkError(urlError)

        guard case .networkError(let underlyingError) = error else {
            Issue.record("Expected networkError case")
            return
        }

        #expect(underlyingError as? URLError == urlError)
        #expect(underlyingError.localizedDescription == urlError.localizedDescription)
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
        let client = try FoliClient(transport: transport, cacheBehavior: .staleWhileRevalidate)
        await client.installCacheForTesting(cache)

        await client.refreshCacheInBackground(
            for: .routes,
            fetch: { ["fresh-routes"] },
            save: { routes, _ in
                await cache.recordSavedRoutes(routes)
            }
        )

        #expect(await client.refreshTracker.hasActiveTask(for: .routes))

        for _ in 0..<40 {
            if await !client.refreshTracker.hasActiveTask(for: .routes) {
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }

        #expect(await !client.refreshTracker.hasActiveTask(for: .routes))
        #expect(await cache.savedRoutes == [["fresh-routes"]])
    }
}

private actor ControlledCache: Foli.Cache {
    let timeoutDuration: Foli.CacheTTL = .default
    private let revalidationResult: Bool
    private(set) var savedRoutes: [[String]] = []

    init(revalidationResult: Bool) {
        self.revalidationResult = revalidationResult
    }

    var currentDatasetId: String? {
        get async throws { nil }
    }

    func loadResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T? { nil }
    func loadStaleResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T? { nil }
    func saveResource<T: Codable & Sendable>(_ value: T, forKey key: Foli.Resource, datasetId: String?) async throws {}

    func clearAllCache() async throws {}
    func clearCache(for type: Foli.Resource) async throws {}
    func hasValidCache(for type: Foli.Resource) async -> Bool { false }
    func cacheAge(for type: Foli.Resource) async -> TimeInterval? { nil }
    func currentDatasetId(for type: Foli.Resource?) async throws -> String? { nil }
    func revalidateCache(for type: Foli.Resource) async throws -> Bool { revalidationResult }
    func fetchLatestDatasetId() async throws -> String { "controlled-dataset" }

    func recordSavedRoutes(_ routes: [String]) {
        savedRoutes.append(routes)
    }
}

extension FoliClient {
    func installCacheForTesting(_ cache: some Foli.Cache) {
        self.cache = cache
    }
}
