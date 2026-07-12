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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchStopTimes(forStop: "4")
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
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

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchShapePoints(forShape: "0_7")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/shapes/0_7")
    }

    // MARK: - Alerts Endpoint Tests

    @Test("fetchAlerts requests alerts root path")
    func fetchAlertsUsesAlertsPath() async throws {
        // Based on actual API response from https://data.foli.fi/alerts
        let payload = #"""
        {
          "servertime": 1672531200,
          "messages": [],
          "cancellations": [],
          "global_message": {},
          "emergency_message": {}
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchAlerts()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/alerts")
    }

    @Test("fetchAlertMessages requests alerts messages path")
    func fetchAlertMessagesUsesMessagesPath() async throws {
        let payload = #"""
        {
          "servertime": 1672531200,
          "messages": [
            {
              "message_id": 1,
              "icon": "BUS",
              "cause": "UNKNOWN_CAUSE",
              "effect": "NO_SERVICE",
              "header": "Test Alert",
              "message": "Test message content",
              "information": null,
              "translations": null,
              "images": null,
              "repeat": [[1672531200, 1704067199]],
              "isactive": true,
              "priority": 200,
              "affected_routes": [],
              "affected_stops": [],
              "categories": [],
              "channel_web": true,
              "channel_stops": null,
              "channel_mobile": null,
              "channel_ticker": null,
              "channel_gtfsrt": null
            }
          ],
          "cancellations": [],
          "global_message": {},
          "emergency_message": {}
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchAlertMessages()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/alerts/messages")
    }

    @Test("fetchCancellations requests alerts cancellations path")
    func fetchCancellationsUsesCancellationsPath() async throws {
        let payload = #"""
        {
          "servertime": 1672531200,
          "messages": [],
          "cancellations": [
            {
              "line": "1",
              "icon": "cancel",
              "cause": "UNKNOWN_CAUSE",
              "departure": 1672531200,
              "stops": [
                {
                  "stop": "123",
                  "arrival": 1672531800,
                  "isactive": true
                }
              ],
              "priority": 100
            }
          ],
          "global_message": {},
          "emergency_message": {}
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchCancellations()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/alerts/cancellations")
    }

    @Test("fetchAlertCategories requests alerts categories path")
    func fetchAlertCategoriesUsesCategoriesPath() async throws {
        let payload = #"""
        [
          {
            "catid": 1,
            "category": "GENERAL",
            "descr_fi": "Yleiset ilmoitukset",
            "descr_sv": null,
            "descr_en": "General alerts"
          }
        ]
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchAlertCategories()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/alerts/categories")
    }

    // MARK: - GeoJSON Endpoint Tests

    @Test("fetchGeoJSONLayers requests geojson layers path")
    func fetchGeoJSONLayersUsesLayersPath() async throws {
        // Based on actual API response from https://data.foli.fi/geojson/layers
        let payload = #"""
        {
          "geojson": {
            "layers": [
              {
                "name": {
                  "fi": "Pysäkit",
                  "sv": "Hållplatser",
                  "en": "Stops"
                },
                "url": "/geojson/stops",
                "metadata": {
                  "name": "name",
                  "popupContent": "name",
                  "textOnly": "name"
                }
              }
            ]
          }
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchGeoJSONLayers()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/layers")
    }

    @Test("fetchPointsOfInterest requests geojson poi path")
    func fetchPointsOfInterestUsesPOIPath() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchPointsOfInterest()
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/poi")
    }

    @Test("fetchPointsOfInterest with category requests geojson poi category path")
    func fetchPointsOfInterestByCategoryUsesCategoryPath() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchPointsOfInterest(inCategory: "service_points")
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/poi/service_points")
    }

    @Test("fetchServiceBounds with normal resolution requests geojson bounds path")
    func fetchServiceBoundsNormalUsesBaseBoundsPath() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchServiceBounds(resolution: .normal, format: .multiPolygon)
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/bounds")
    }

    @Test("fetchServiceBounds with strict resolution requests strict bounds path")
    func fetchServiceBoundsStrictUsesStrictPath() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchServiceBounds(resolution: .strict, format: .multiPolygon)
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/bounds/strict")
    }

    @Test("fetchServiceBounds with compact resolution requests compact bounds path")
    func fetchServiceBoundsCompactUsesCompactPath() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchServiceBounds(resolution: .compact, format: .multiPolygon)
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/bounds/compact")
    }

    @Test("fetchServiceBounds with multiLineString format appends ml suffix")
    func fetchServiceBoundsMultiLineStringAppendsMlSuffix() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchServiceBounds(resolution: .normal, format: .multiLineString)
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/bounds/ml")
    }

    @Test("fetchServiceBounds with strict and multiLineString combines both modifiers")
    func fetchServiceBoundsStrictMultiLineStringCombinesModifiers() async throws {
        let payload = #"""
        {
          "type": "FeatureCollection",
          "features": []
        }
        """#.data(using: .utf8)!
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: payload)
        }

        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        _ = try await client.fetchServiceBounds(resolution: .strict, format: .multiLineString)
        let requests = await transport.requests()

        #expect(requests.count == 1)
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/geojson/bounds/strict/ml")
    }
}
