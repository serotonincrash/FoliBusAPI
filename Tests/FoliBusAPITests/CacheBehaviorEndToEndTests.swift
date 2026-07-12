import Foundation
import Testing
@testable import FoliBusAPI

/// End-to-end tests for every `Foli.CacheBehavior`: real `DiskCache` in an isolated
/// temp directory, mock transport, and a controllable dataset ID for revalidation.
@Suite("CacheBehavior End-to-End Tests")
struct CacheBehaviorEndToEndTests {
    private static let routesPayload = #"""
    [
      {
        "route_id": "25",
        "agency_id": "2",
        "route_short_name": "L14",
        "route_long_name": "Loukinainen-Avanti",
        "route_desc": "",
        "route_type": 3,
        "route_url": "",
        "route_color": "000000",
        "route_text_color": "ffffff"
      }
    ]
    """#.data(using: .utf8)!

    /// Holds the "latest" dataset ID so tests can invalidate cached entries on demand.
    private actor DatasetBox {
        private(set) var current: String
        init(_ id: String) { self.current = id }
        func set(_ id: String) { current = id }
    }

    private func makeClient(
        behavior: Foli.CacheBehavior,
        ttl: Foli.CacheTTL = .default
    ) async throws -> (client: FoliClient, transport: MockTransport, directory: URL, dataset: DatasetBox) {
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: Self.routesPayload)
        }
        let dataset = DatasetBox("dataset-1")
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "FoliBusAPITests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let cache = try Foli.DiskCache(
            timeout: ttl,
            directory: directory,
            datasetIdFetcher: { await dataset.current }
        )
        let client = try FoliClient(transport: transport, cacheBehavior: behavior)
        await client.installCacheForTesting(cache)
        return (client, transport, directory, dataset)
    }

    @Test("cachedOrFetch fetches on miss and serves from cache on hit")
    func cachedOrFetchMissThenHit() async throws {
        let (client, transport, directory, _) = try await makeClient(behavior: .cachedOrFetch)
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = try await client.fetchRoutes()
        let second = try await client.fetchRoutes()

        #expect(first.count == 1)
        #expect(second == first)
        #expect(await transport.requests().count == 1, "second call must be served from cache")
    }

    @Test("cachedOrFetch revalidates an expired entry without refetching when the dataset is unchanged")
    func cachedOrFetchRevalidatesExpiredEntry() async throws {
        let (client, transport, directory, _) = try await makeClient(
            behavior: .cachedOrFetch,
            ttl: Foli.CacheTTL(validityDuration: 0.01)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchRoutes()
        try await Task.sleep(for: .milliseconds(50))
        let second = try await client.fetchRoutes()

        #expect(second.count == 1)
        #expect(await transport.requests().count == 1, "unchanged dataset should revalidate, not refetch")
    }

    @Test("cachedOrFetch synchronously refetches when the dataset changed, rather than serving stale data")
    func cachedOrFetchRefetchesSynchronouslyOnDatasetChange() async throws {
        let (client, transport, directory, dataset) = try await makeClient(
            behavior: .cachedOrFetch,
            ttl: Foli.CacheTTL(validityDuration: 0.01)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchRoutes()           // miss → fetch + save (1 request)
        try await Task.sleep(for: .milliseconds(50))  // entry expires
        await dataset.set("dataset-2")                // published dataset changes

        let second = try await client.fetchRoutes()   // must refetch synchronously, not serve stale

        #expect(second.count == 1)
        #expect(await transport.requests().count == 2, "a confirmed dataset change must trigger a synchronous refetch")
    }

    @Test("cachedOrFetch serves stale data when revalidation is inconclusive (fetcher throws)")
    func cachedOrFetchServesStaleOnRevalidationError() async throws {
        struct RevalidationFailure: Error {}

        let directory = FileManager.default.temporaryDirectory
            .appending(path: "FoliBusAPITests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }

        let cache = try Foli.DiskCache(
            timeout: Foli.CacheTTL(validityDuration: 0.01),
            directory: directory,
            datasetIdFetcher: { throw RevalidationFailure() }
        )

        // Pre-populate an expired entry directly, bypassing the network.
        let route = try JSONDecoder().decode(Foli.RouteList.self, from: Self.routesPayload).routes[0]
        let entry = Foli.DiskCache.CachedData(
            metadata: Foli.DiskCache.DatasetMetadata(datasetId: "dataset-1", cachedAt: Date(timeIntervalSinceNow: -100)),
            data: [route]
        )
        let fileURL = try await cache.fileURL(for: .routes)
        try JSONEncoder().encode(entry).write(to: fileURL)

        // The transport must never be consulted: revalidation fails before any fetch,
        // and the stale entry should be served instead of propagating the error.
        let transport = MockTransport { request in
            Issue.record("fetch should not occur when the stale entry is served")
            return try makeDataResponse(for: request, data: Self.routesPayload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .cachedOrFetch)
        await client.installCacheForTesting(cache)

        let routes = try await client.fetchRoutes()

        #expect(routes == [route])
        #expect(await transport.requests().isEmpty, "a transient revalidation error must serve stale data, not crash or refetch")
    }

    @Test("staleWhileRevalidate serves stale data and refreshes in the background on dataset change")
    func staleWhileRevalidateServesStaleThenRefreshes() async throws {
        let (client, transport, directory, dataset) = try await makeClient(
            behavior: .staleWhileRevalidate,
            ttl: Foli.CacheTTL(validityDuration: 0.01)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchRoutes()          // miss → fetch + save (1 request)
        try await Task.sleep(for: .milliseconds(50)) // entry expires
        await dataset.set("dataset-2")               // published dataset changes

        let stale = try await client.fetchRoutes()   // stale served immediately
        #expect(stale.count == 1)

        // Background refresh should notice the dataset change and refetch.
        var refreshed = false
        for _ in 0..<40 {
            if await transport.requests().count >= 2 {
                refreshed = true
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }
        #expect(refreshed, "background refresh should refetch after a dataset change")
    }

    @Test("forceRefresh always fetches even with a fresh cache")
    func forceRefreshAlwaysFetches() async throws {
        let (client, transport, directory, _) = try await makeClient(behavior: .forceRefresh)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchRoutes()
        _ = try await client.fetchRoutes()

        #expect(await transport.requests().count == 2)
    }

    @Test("cachedOnly serves an expired entry with zero network requests")
    func cachedOnlyServesExpiredEntryOffline() async throws {
        let (client, transport, directory, _) = try await makeClient(behavior: .cachedOnly)
        defer { try? FileManager.default.removeItem(at: directory) }

        // Pre-populate with a long-expired entry, bypassing the network entirely.
        let route = try JSONDecoder().decode(Foli.RouteList.self, from: Self.routesPayload).routes[0]
        let entry = Foli.DiskCache.CachedData(
            metadata: Foli.DiskCache.DatasetMetadata(datasetId: "dataset-1", cachedAt: Date(timeIntervalSinceNow: -100_000)),
            data: [route]
        )
        let cache = try #require(await client.cache as? Foli.DiskCache)
        let fileURL = try await cache.fileURL(for: .routes)
        try JSONEncoder().encode(entry).write(to: fileURL)

        let routes = try await client.fetchRoutes()

        #expect(routes == [route])
        #expect(await transport.requests().isEmpty, ".cachedOnly must never touch the network")
    }

    @Test("cachedOnly throws cacheMiss on an empty cache with zero network requests")
    func cachedOnlyThrowsCacheMissWhenEmpty() async throws {
        let (client, transport, directory, _) = try await makeClient(behavior: .cachedOnly)
        defer { try? FileManager.default.removeItem(at: directory) }

        await #expect(throws: Foli.CacheError.self) {
            _ = try await client.fetchRoutes()
        }
        #expect(await transport.requests().isEmpty)
    }

    @Test("noCache fetches without writing anything to disk")
    func noCacheWritesNothing() async throws {
        let (client, transport, directory, _) = try await makeClient(behavior: .noCache)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchRoutes()

        #expect(await transport.requests().count == 1)
        let contents = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(contents.isEmpty, ".noCache must not write cache files, found: \(contents)")
    }
}
