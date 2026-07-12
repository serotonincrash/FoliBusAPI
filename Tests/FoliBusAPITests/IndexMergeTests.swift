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

    @Test("rebuild with a duplicated ID does not trap and keeps the later entry")
    func rebuildWithDuplicateIdKeepsLaterEntry() async throws {
        let indexes = FoliIndexes()

        let firstStop = Foli.Stop(id: "dup", name: "First")
        let secondStop = Foli.Stop(id: "dup", name: "Second")
        // Prior to the fix, `Dictionary(uniqueKeysWithValues:)` traps on a duplicate key.
        await indexes.rebuildStops(using: [firstStop, secondStop])
        #expect(await indexes.stop(for: "dup")?.name == "Second")

        let firstAgency = Foli.Agency(id: "dup", name: "First Agency")
        let secondAgency = Foli.Agency(id: "dup", name: "Second Agency")
        await indexes.rebuildAgencies(using: [firstAgency, secondAgency])
        #expect(await indexes.agency(for: "dup")?.name == "Second Agency")

        let firstRoute = Foli.Route(id: "dup", shortName: "1", longName: "First Route", type: 3)
        let secondRoute = Foli.Route(id: "dup", shortName: "1", longName: "Second Route", type: 3)
        await indexes.rebuildRoutes(using: [firstRoute, secondRoute])
        #expect(await indexes.route(for: "dup")?.longName == "Second Route")

        let firstTrip = try makeTrip(id: "dup", route: "1")
        let secondTripJSON = """
        {
          "route_id": "1",
          "service_id": "A:TEST",
          "trip_id": "dup",
          "trip_headsign": "Second",
          "direction_id": 1,
          "block_id": "block-dup-2",
          "shape_id": "shape-1",
          "wheelchair_accessible": 1
        }
        """.data(using: .utf8)!
        let secondTrip = try JSONDecoder().decode(Foli.Trip.self, from: secondTripJSON)
        await indexes.rebuildTrips(using: [firstTrip, secondTrip])
        #expect(await indexes.trip(for: "dup")?.tripHeadsign == "Second")

        let firstCalendar = Foli.Calendar(
            id: "dup", monday: true, tuesday: true, wednesday: true, thursday: true,
            friday: true, saturday: false, sunday: false, startDateCode: "20260101", endDateCode: "20260201"
        )
        let secondCalendar = Foli.Calendar(
            id: "dup", monday: false, tuesday: false, wednesday: false, thursday: false,
            friday: false, saturday: true, sunday: true, startDateCode: "20260301", endDateCode: "20260401"
        )
        await indexes.rebuildCalendars(using: [firstCalendar, secondCalendar])
        #expect(await indexes.calendar(for: "dup")?.startDateCode == "20260301")
    }
}
