import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Endpoint Compatibility Tests")
struct EndpointCompatibilityTests {
    @Test("fetchRoutes requests GTFS routes path")
    func fetchRoutesUsesGTFSRoutesPath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/routes
        let payload = #"""
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
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchRoutes()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/routes")
    }

    @Test("fetchTrips requests GTFS trips all path")
    func fetchTripsUsesTripsAllPath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/trips/all
        let payload = #"""
        [
          {
            "route_id": "1",
            "service_id": "A:FOLI_Arki",
            "trip_id": "00010000__1000generatedBlock",
            "trip_headsign": "Satama",
            "direction_id": 1,
            "block_id": "1000generatedBlock",
            "shape_id": "0_154",
            "wheelchair_accessible": 2
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchTrips()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/trips/all")
    }

    @Test("fetchTrips for route requests GTFS route-specific path")
    func fetchTripsForRouteUsesRoutePath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/trips/route/1
        let payload = #"""
        [
          {
            "service_id": "A:FÖLI_Kesä_2015_ver3",
            "trip_id": "0000null__1000generatedBlock",
            "trip_headsign": "Satama",
            "direction_id": 1,
            "block_id": "1000generatedBlock",
            "shape_id": "113",
            "wheelchair_accessible": 2
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchTrips(forRoute: "1")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/trips/route/1")
    }

    @Test("fetchStopTimes for trip requests GTFS trip stop-times path")
    func fetchStopTimesForTripUsesTripPath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/stop_times/trip/%trip_id%
        let payload = #"""
        [
          {
            "arrival_time": "05:20:00",
            "departure_time": "05:20:00",
            "stop_id": "1586",
            "stop_sequence": 0,
            "stop_headsign": "",
            "pickup_type": 0,
            "drop_off_type": 0,
            "shape_dist_traveled": 0
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchStopTimes(forTrip: "0000null__1901generatedBlock")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/stop_times/trip/0000null__1901generatedBlock")
    }

    @Test("fetchStopTimes for stop requests GTFS stop stop-times path")
    func fetchStopTimesForStopUsesStopPath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/stop_times/stop/4
        let payload = #"""
        [
          {
            "trip_id": "0000null__1901generatedBlock",
            "arrival_time": "05:20:00",
            "departure_time": "05:20:00",
            "stop_sequence": 0,
            "stop_headsign": "",
            "pickup_type": 0,
            "drop_off_type": 0,
            "shape_dist_traveled": 0
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchStopTimes(stopID: "4")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/stop_times/stop/4")
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

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchStopMonitoring(for: "1000")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/siri/sm/1000")
    }

    @Test("fetchAgencies requests GTFS agency path")
    func fetchAgenciesUsesAgencyPath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/agency
        let payload = #"""
        [
          {
            "agency_id": "11",
            "agency_name": "SLA",
            "agency_url": "https://www.google.fi/",
            "agency_timezone": "Europe/Helsinki",
            "agency_lang": "  ",
            "agency_phone": "",
            "agency_fare_url": null
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchAgencies()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/agency")
    }

    @Test("fetchCalendars requests GTFS calendar path")
    func fetchCalendarsUsesCalendarPath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/calendar
        let payload = #"""
        {
          "A:FÖLI_Kesä_2015_ver3": {
            "monday": false,
            "tuesday": false,
            "wednesday": false,
            "thursday": false,
            "friday": false,
            "saturday": false,
            "sunday": false,
            "start_date": "20150601",
            "end_date": "20150628"
          }
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchShapeRouteIDs()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/shapes")
    }

    @Test("fetchShapePoints for shape requests GTFS shape-specific path")
    func fetchShapePointsForShapeUsesShapePath() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/shapes/0_7
        let payload = #"""
        [
          {
            "lat": 60.51109,
            "lon": 22.27421,
            "traveled": 0
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchShapePoints(forRouteId: "0_7")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/shapes/0_7")
    }
}
