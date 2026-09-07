import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Transport Integration Tests")
struct TransportIntegrationTests {
    @Test("request transport records GTFS URL and decodes success payload")
    func requestRecordsURLAndDecodesPayload() async throws {
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
        let routes = try await client.fetchRoutes()
        let requests = await transport.requests()

        #expect(routes.count == 1)
        #expect(routes.first?.id == "25")
        #expect(requests.count == 1)
        #expect(requests.first?.httpMethod == "GET")
        #expect(requests.first?.url?.absoluteString == "https://data.foli.fi/gtfs/routes")
    }

    @Test("non-2xx responses map to invalidResponse")
    func non2xxResponseMapsToInvalidResponse() async throws {
        let payload = Data("[]".utf8)
        let transport = MockTransport { request in
            try makeDataResponse(for: request, statusCode: 503, data: payload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        do {
            _ = try await client.fetchRoutes()
            Issue.record("Expected fetchRoutes to throw invalidResponse")
        } catch let error as Foli.APIError {
            guard case .invalidResponse = error else {
                Issue.record("Expected invalidResponse, got \(error)")
                return
            }
        }
    }

    @Test("404 on a GTFS collection endpoint decodes as an empty result")
    func notFoundCollectionDecodesEmpty() async throws {
        // Real Föli behavior: /trips/route/<id> for a route with no scheduled trips
        // (e.g. route 8 = line 3T outside its service window) answers
        // 404 {"success":false,"reason":"path_not_exists"}.
        let payload = Data(#"{"success":false,"reason":"path_not_exists"}"#.utf8)
        let transport = MockTransport { request in
            try makeDataResponse(for: request, statusCode: 404, data: payload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        let trips = try await client.fetchTrips(forRoute: "8")
        #expect(trips.isEmpty)
    }

    @Test("404 on an object-shaped response still maps to invalidResponse")
    func notFoundObjectStillThrows() async throws {
        let payload = Data("[]".utf8)
        let transport = MockTransport { request in
            try makeDataResponse(for: request, statusCode: 404, data: payload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        do {
            _ = try await client.fetchArrivals(for: "1000")
            Issue.record("Expected fetchArrivals to throw invalidResponse")
        } catch let error as Foli.APIError {
            guard case .invalidResponse = error else {
                Issue.record("Expected invalidResponse, got \(error)")
                return
            }
        }
    }

    @Test("transport-thrown errors map to networkError")
    func thrownTransportErrorMapsToNetworkError() async throws {
        let transport = MockTransport { _ in
            throw URLError(.timedOut)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)

        do {
            _ = try await client.fetchRoutes()
            Issue.record("Expected fetchRoutes to throw networkError")
        } catch let error as Foli.APIError {
            guard case .networkError(let wrappedError) = error,
                  let urlError = wrappedError as? URLError else {
                Issue.record("Expected networkError wrapping URLError, got \(error)")
                return
            }
            #expect(urlError.code == .timedOut)
        }
    }
}
