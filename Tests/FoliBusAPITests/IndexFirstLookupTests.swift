import Foundation
import Testing
@testable import FoliBusAPI

/// By-ID lookups answer from a recently rebuilt index instead of re-resolving (and
/// re-decoding) the whole collection through the cache on every call.
///
/// Deleting the cache directory after the first load makes any re-resolution visible:
/// it misses on disk and has to go back to the network.
@Suite("Index-First Lookup Tests")
struct IndexFirstLookupTests {
    private static let stopsPayload = #"""
    {
      "1": {"stop_name": "Central Station"},
      "2": {"stop_name": "Market Square"}
    }
    """#.data(using: .utf8)!

    private static let tripsPayload = #"""
    [
      {
        "route_id": "1",
        "service_id": "A:TEST",
        "trip_id": "trip-a",
        "trip_headsign": "Test",
        "direction_id": 1,
        "block_id": "block-a",
        "shape_id": "shape-1",
        "wheelchair_accessible": 1
      }
    ]
    """#.data(using: .utf8)!

    private func makeClient(
        behavior: Foli.CacheBehavior,
        ttl: Foli.CacheTTL = .default
    ) async throws -> (client: FoliClient, transport: MockTransport, directory: URL) {
        let transport = MockTransport { request in
            let path = request.url?.path ?? ""
            let data = path.hasSuffix("/stops") ? Self.stopsPayload : Self.tripsPayload
            return try makeDataResponse(for: request, data: data)
        }
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "FoliBusAPITests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let cache = try Foli.DiskCache(
            timeout: ttl,
            directory: directory,
            datasetIdFetcher: { "dataset-1" }
        )
        let client = try FoliClient(transport: transport, cacheBehavior: behavior, cacheTTL: ttl)
        await client.installCacheForTesting(cache)
        return (client, transport, directory)
    }

    private func requestCount(_ transport: MockTransport, endingWith suffix: String) async -> Int {
        await transport.requests().filter { $0.url?.path.hasSuffix(suffix) == true }.count
    }

    @Test("cachedOrFetch: lookups after a load skip the cache, misses included")
    func cachedOrFetchAnswersFromIndex() async throws {
        let (client, transport, directory) = try await makeClient(behavior: .cachedOrFetch)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchStops()
        try FileManager.default.removeItem(at: directory)

        #expect(try await client.stop(for: "1")?.name == "Central Station")
        #expect(try await client.stop(for: "2")?.name == "Market Square")
        #expect(try await client.stop(for: "missing") == nil)
        #expect(await requestCount(transport, endingWith: "/stops") == 1)
    }

    @Test("A cold index still resolves through the cache")
    func coldIndexResolves() async throws {
        let (client, transport, directory) = try await makeClient(behavior: .cachedOrFetch)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try await client.stop(for: "1")?.name == "Central Station")
        #expect(await requestCount(transport, endingWith: "/stops") == 1)
    }

    @Test("forceRefresh: every lookup re-resolves")
    func forceRefreshAlwaysResolves() async throws {
        let (client, transport, directory) = try await makeClient(behavior: .forceRefresh)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.stop(for: "1")
        _ = try await client.stop(for: "2")
        #expect(await requestCount(transport, endingWith: "/stops") == 2)
    }

    @Test("The trust window never outlasts a shorter cache TTL")
    func trustWindowCappedByTTL() async throws {
        let (client, transport, directory) = try await makeClient(
            behavior: .cachedOrFetch,
            ttl: Foli.CacheTTL(validityDuration: 0.01)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchStops()
        try FileManager.default.removeItem(at: directory)
        try await Task.sleep(for: .milliseconds(50))

        _ = try await client.stop(for: "1")
        #expect(await requestCount(transport, endingWith: "/stops") == 2)
    }

    @Test("clearCache stops the index from answering")
    func clearCacheInvalidatesIndex() async throws {
        let (client, transport, directory) = try await makeClient(behavior: .cachedOrFetch)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchStops()
        try await client.clearCache(for: .stops)

        _ = try await client.stop(for: "1")
        #expect(await requestCount(transport, endingWith: "/stops") == 2)
    }

    @Test("Route-scoped trip merges don't make the partial trip index authoritative")
    func partialTripIndexNotTrusted() async throws {
        let (client, transport, directory) = try await makeClient(behavior: .cachedOrFetch)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await client.fetchTrips(forRoute: "1")
        _ = try await client.trip(for: "trip-a")
        #expect(await requestCount(transport, endingWith: "/trips/all") == 1)
    }
}
