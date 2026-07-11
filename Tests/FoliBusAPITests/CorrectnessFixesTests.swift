import Foundation
import Testing
@testable import FoliBusAPI

// MARK: - A1: GTFS date parsing pinned to Europe/Helsinki

@Suite("GTFS Date Parsing Tests")
struct GTFSDateParsingTests {
    @Test("a known YYYYMMDD code maps to Helsinki midnight regardless of device TZ")
    func parsesToHelsinkiMidnight() throws {
        let date = try #require(GTFSDateParser.date(from: "20260710"))

        var helsinkiCalendar = Foundation.Calendar(identifier: .gregorian)
        helsinkiCalendar.timeZone = TimeZone(identifier: "Europe/Helsinki")!

        let components = helsinkiCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 7)
        #expect(components.day == 10)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("Foli.Calendar and Foli.CalendarDate agree with GTFSDateParser directly")
    func calendarModelsUseGTFSDateParser() throws {
        let calendar = Foli.Calendar(
            id: "svc",
            monday: true, tuesday: true, wednesday: true, thursday: true, friday: true,
            saturday: false, sunday: false,
            startDateCode: "20260101",
            endDateCode: "20261231"
        )
        #expect(calendar.startDate == GTFSDateParser.date(from: "20260101"))
        #expect(calendar.endDate == GTFSDateParser.date(from: "20261231"))

        let calendarDate = Foli.CalendarDate(serviceId: "svc", dateString: "20260704", exceptionType: 1)
        #expect(calendarDate.date == GTFSDateParser.date(from: "20260704"))
    }

    @Test("malformed date codes return nil rather than misparsing")
    func rejectsMalformedCodes() {
        #expect(GTFSDateParser.date(from: "") == nil)
        #expect(GTFSDateParser.date(from: "2026071") == nil) // 7 digits
        #expect(GTFSDateParser.date(from: "202607100") == nil) // 9 digits
        #expect(GTFSDateParser.date(from: "2026-07-10") == nil) // wrong shape
        #expect(GTFSDateParser.date(from: "abcdefgh") == nil) // non-numeric
    }
}

// MARK: - A3: Percent-encoded path components

@Suite("Path Component Encoding Tests")
struct PathComponentEncodingTests {
    @Test("hostile IDs are percent-encoded rather than producing a different path or invalidURL")
    func hostileIdsAreEncoded() async throws {
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: Data("[]".utf8))
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        _ = try await client.fetchShapePoints(forShape: "a/b?x=1")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        let urlString = try #require(requests.first?.url?.absoluteString)
        // The hostile characters must be encoded, not interpreted as path/query syntax.
        #expect(urlString == "https://data.foli.fi/gtfs/shapes/a%2Fb%3Fx%3D1")
        #expect(!urlString.contains("a/b?x=1"))
    }

    @Test("a space in an ID is percent-encoded")
    func spaceIsEncoded() async throws {
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: Data("[]".utf8))
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        _ = try await client.fetchStopTimes(forStop: "stop 1")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        let urlString = try #require(requests.first?.url?.absoluteString)
        #expect(urlString == "https://data.foli.fi/gtfs/stop_times/stop/stop%201")
    }

    @Test("underscores and hyphens in real GTFS IDs pass through unescaped")
    func unreservedCharactersPassThrough() {
        #expect(FoliRequester.pathComponent("0_7") == "0_7")
        #expect(FoliRequester.pathComponent("0000null__1901generatedBlock") == "0000null__1901generatedBlock")
        #expect(FoliRequester.pathComponent("service-points.v2") == "service-points.v2")
    }
}

// MARK: - A8: Shape sequence 0 is preserved, not renumbered

@Suite("Shape Sequence Tests")
struct ShapeSequenceTests {
    @Test("explicit sequences [0, 1] yield distinct IDs and preserved order")
    func explicitZeroSequencePreserved() async throws {
        let payload = #"""
        [
          { "shape_id": "S1", "shape_pt_lat": 60.45, "shape_pt_lon": 22.25, "shape_pt_sequence": 0 },
          { "shape_id": "S1", "shape_pt_lat": 60.46, "shape_pt_lon": 22.26, "shape_pt_sequence": 1 }
        ]
        """#.data(using: .utf8)!

        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        let points = try await client.fetchShapePoints(forShape: "S1")

        #expect(points.count == 2)
        #expect(points[0].sequence == 0)
        #expect(points[1].sequence == 1)
        // Distinct, not colliding IDs: the sequence-0 point must not be renumbered to 1.
        #expect(points[0].id == "S1-0")
        #expect(points[1].id == "S1-1")
        #expect(Set(points.map(\.id)).count == 2)
    }

    @Test("a payload missing shape_pt_sequence entirely back-fills from array index")
    func missingSequenceBackfillsFromIndex() async throws {
        let payload = #"""
        [
          { "lat": 60.45, "lon": 22.25, "traveled": 0.0 },
          { "lat": 60.46, "lon": 22.26, "traveled": 12.5 }
        ]
        """#.data(using: .utf8)!

        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        let points = try await client.fetchShapePoints(forShape: "S2")

        #expect(points.count == 2)
        #expect(points[0].sequence == 1)
        #expect(points[1].sequence == 2)
    }
}
