import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Endpoint Compatibility Tests")
struct EndpointCompatibilityTests {
    @Test("fetchRoutes requests GTFS routes path")
    func fetchRoutesUsesGTFSRoutesPath() async throws {
        let payload = #"""
        [
          {
            "route_id": "1",
            "agency_id": "2",
            "route_short_name": "1",
            "route_long_name": "Center",
            "route_desc": "",
            "route_type": 3,
            "route_url": "",
            "route_color": "000000",
            "route_text_color": "ffffff"
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchRoutes()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/routes")
    }

    @Test("fetchTrips requests GTFS trips all path")
    func fetchTripsUsesTripsAllPath() async throws {
        let payload = #"""
        [
          {
            "route_id": "10",
            "service_id": "WKD",
            "trip_id": "TRIP-1",
            "trip_headsign": "Harbor",
            "direction_id": 0,
            "block_id": "BLOCK-1",
            "shape_id": "SHAPE-1",
            "wheelchair_accessible": 2
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchTrips()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/trips/all")
    }

    @Test("fetchTrips for route requests GTFS route-specific path")
    func fetchTripsForRouteUsesRoutePath() async throws {
        let payload = #"""
        [
          {
            "service_id": "WKD",
            "trip_id": "TRIP-15",
            "trip_headsign": "Airport",
            "direction_id": 1,
            "block_id": "BLOCK-15",
            "shape_id": "SHAPE-15",
            "wheelchair_accessible": 2
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchTrips(forRoute: "15")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/trips/route/15")
    }

    @Test("fetchStopTimes for trip requests GTFS trip stop-times path")
    func fetchStopTimesForTripUsesTripPath() async throws {
        let payload = #"""
        [
          {
            "arrival_time": "08:00:00",
            "departure_time": "08:01:00",
            "stop_id": "1000",
            "stop_sequence": 1,
            "stop_headsign": "Center",
            "pickup_type": 0,
            "drop_off_type": 0,
            "shape_dist_traveled": 123.5
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchStopTimes(forTrip: "TRIP-1")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/stop_times/trip/TRIP-1")
    }

    @Test("fetchStopTimes for stop requests GTFS stop stop-times path")
    func fetchStopTimesForStopUsesStopPath() async throws {
        let payload = #"""
        [
          {
            "trip_id": "TRIP-1",
            "arrival_time": "08:00:00",
            "departure_time": "08:01:00",
            "stop_sequence": 1,
            "stop_headsign": "Center",
            "pickup_type": 0,
            "drop_off_type": 0,
            "shape_dist_traveled": 123.5
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchStopTimes(stopID: "1000")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/stop_times/stop/1000")
    }

    @Test("fetchStopMonitoring requests SIRI stop-monitoring path")
    func fetchStopMonitoringUsesSIRIPath() async throws {
        let payload = #"""
        {
          "sys": "SM",
          "status": "OK",
          "servertime": 1710000000,
          "result": [
            {
              "recordedattime": 1710000000,
              "lineref": "1",
              "monitored": true,
              "latitude": 60.4518,
              "longitude": 22.2666,
              "originaimeddeparturetime": 1710000000,
              "destinationaimedarrivaltime": 1710000600,
              "destinationdisplay": "Satama",
              "aimedarrivaltime": 1710000300,
              "expectedarrivaltime": 1710000360,
              "aimeddeparturetime": 1710000420,
              "expecteddeparturetime": 1710000480,
              "delay": 60
            }
          ]
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchStopMonitoring(for: "1000")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/siri/sm/1000")
    }

    @Test("fetchAgencies requests GTFS agency path")
    func fetchAgenciesUsesAgencyPath() async throws {
        let payload = #"""
        [
          {
            "agency_id": "FOLI",
            "agency_name": "Foli",
            "agency_url": "https://www.foli.fi",
            "agency_timezone": "Europe/Helsinki"
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchAgencies()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/agency")
    }

    @Test("fetchCalendars requests GTFS calendar path")
    func fetchCalendarsUsesCalendarPath() async throws {
        let payload = #"""
        {
          "WKD": {
            "monday": true,
            "tuesday": true,
            "wednesday": true,
            "thursday": true,
            "friday": true,
            "saturday": false,
            "sunday": false,
            "start_date": "20260101",
            "end_date": "20261231"
          }
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchCalendars()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/calendar")
    }

    @Test("fetchShapePoints requests GTFS shapes path")
    func fetchShapePointsUsesShapesPath() async throws {
        let payload = #"""
        [
          "1",
          "10"
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchShapeRouteIDs()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/shapes")
    }

    @Test("fetchShapePoints for shape requests GTFS shape-specific path")
    func fetchShapePointsForShapeUsesShapePath() async throws {
        let payload = #"""
        [
          {
            "lat": 60.4518,
            "lon": 22.2666,
            "traveled": 12.5
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cachedBy: .noCache)
        _ = try await client.fetchShapePoints(forShapeID: "SHAPE-1")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/shapes/SHAPE-1")
    }
}
