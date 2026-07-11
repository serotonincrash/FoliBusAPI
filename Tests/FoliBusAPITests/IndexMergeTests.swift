import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Index Merge Tests")
struct IndexMergeTests {
    private func makeTrip(id: String, route: String) throws -> Foli.Trip {
        let json = """
        {
          "route_id": "\(route)",
          "service_id": "A:TEST",
          "trip_id": "\(id)",
          "trip_headsign": "Test",
          "direction_id": 1,
          "block_id": "block-\(id)",
          "shape_id": "shape-\(route)",
          "wheelchair_accessible": 1
        }
        """.data(using: .utf8)!
        return try JSONDecoder().decode(Foli.Trip.self, from: json)
    }

    @Test("mergeTrips keeps existing entries; rebuildTrips replaces them")
    func mergePreservesExistingRebuildReplaces() async throws {
        let indexes = FoliIndexes()
        let tripA = try makeTrip(id: "trip-a", route: "1")
        let tripB = try makeTrip(id: "trip-b", route: "1")
        let tripC = try makeTrip(id: "trip-c", route: "2")

        await indexes.rebuildTrips(using: [tripA, tripB])
        await indexes.mergeTrips([tripC])

        // A route-scoped merge must not evict trips from other routes.
        #expect(await indexes.trip(for: "trip-a") != nil)
        #expect(await indexes.trip(for: "trip-b") != nil)
        #expect(await indexes.trip(for: "trip-c") != nil)

        // A full rebuild after a merge must not be skipped by the stale fingerprint.
        await indexes.rebuildTrips(using: [tripA, tripB])
        #expect(await indexes.trip(for: "trip-c") == nil)
        #expect(await indexes.trip(for: "trip-a") != nil)
    }
}
