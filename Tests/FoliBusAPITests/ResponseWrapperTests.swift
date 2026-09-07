import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Response Wrapper Tests")
struct ResponseWrapperTests {
    @Test("decode arrival response from current siri contract")
    func decodeArrivalResponse() throws {
        // Based on actual API response from https://data.foli.fi/siri/sm/4
        let json = """
        {
          "sys": "SM",
          "status": "OK",
          "servertime": 1432453114,
          "result": [
            {
              "recordedattime": 1432453110,
              "lineref": "15",
              "monitored": true,
              "latitude": 60.454883,
              "longitude": 22.2696,
              "originaimeddeparturetime": 1432451700,
              "destinationaimedarrivaltime": 1432455180,
              "destinationdisplay": "Kakskerta Brinkhallin kautta",
              "aimedarrivaltime": 1432453320,
              "expectedarrivaltime": 1432453229,
              "aimeddeparturetime": 1432453500,
              "expecteddeparturetime": 1432453409,
              "delay": -91
            }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.ArrivalResponse.self, from: json)
        let firstArrival = try #require(decoded.result.first)

        #expect(decoded.isValid)
        #expect(decoded.result.count == 1)
        #expect(firstArrival.lineRef == "15")
        #expect(firstArrival.destinationDisplay == "Kakskerta Brinkhallin kautta")
        #expect(firstArrival.latitude == 60.454883)
    }

    @Test("unknown arrival status decodes as unknown and surfaces as a server error")
    func decodeArrivalResponseWithUnknownStatus() async throws {
        let json = """
        { "sys": "SM", "status": "MAINTENANCE", "servertime": 1432453114, "result": [] }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.ArrivalResponse.self, from: json)
        #expect(decoded.status == .unknown("MAINTENANCE"))
        #expect(decoded.status.rawValue == "MAINTENANCE")
        #expect(!decoded.isValid)

        // End-to-end: an unrecognized status is a server error, not a decoding failure.
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: json)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        do {
            _ = try await client.fetchArrivals(for: "1")
            Issue.record("Expected fetchArrivals to throw for an unknown status")
        } catch let error as Foli.APIError {
            guard case .serverError(let status) = error else {
                Issue.record("Expected serverError, got \(error)")
                return
            }
            #expect(status == "MAINTENANCE")
        }
    }

    @Test("unknown vehicle monitoring status decodes as unknown and surfaces as a server error")
    func decodeVehicleMonitoringResponseWithUnknownStatus() async throws {
        let json = """
        {
          "sys": "VM",
          "status": "MAINTENANCE",
          "servertime": 1433246786,
          "result": {
            "responsetimestamp": 1433246786,
            "producerref": "Foli",
            "responsemessageidentifier": "vm-test",
            "status": true,
            "moredata": false,
            "vehicles": {}
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.VehicleMonitoringResponse.self, from: json)
        #expect(decoded.status == .unknown("MAINTENANCE"))
        #expect(decoded.status.rawValue == "MAINTENANCE")
        #expect(!decoded.isValid)

        // End-to-end: an unrecognized status is a server error, not a decoding failure.
        let transport = MockTransport { request in
            try makeDataResponse(for: request, data: json)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .noCache)
        do {
            _ = try await client.fetchVehicleLocations()
            Issue.record("Expected fetchVehicleLocations to throw for an unknown status")
        } catch let error as Foli.APIError {
            guard case .serverError(let status) = error else {
                Issue.record("Expected serverError, got \(error)")
                return
            }
            #expect(status == "MAINTENANCE")
        }
    }

}
