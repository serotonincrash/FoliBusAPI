import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Response Wrapper Tests")
struct ResponseWrapperTests {
    @Test("decode calendar dates list from documented dictionary shape")
    func decodeCalendarDatesList() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/calendar_dates
        let json = """
        {
          "A:FÖLI_Kesä_2015_ver3": [
            { "date": "20150601", "exception_type": 0 },
            { "date": "20150626", "exception_type": 0 }
          ],
          "S:FÖLI_Kesä_2015_ver3": [
            { "date": "20150607", "exception_type": 0 }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.CalendarDatesList.self, from: json)
        let serviceIds = decoded.calendarDates.map(\.serviceId)
        let dateStrings = decoded.calendarDates.map(\.dateString)
        let exceptionTypes = decoded.calendarDates.map(\.exceptionType)

        #expect(decoded.calendarDates.count == 3)
        #expect(serviceIds.contains("A:FÖLI_Kesä_2015_ver3"))
        #expect(serviceIds.contains("S:FÖLI_Kesä_2015_ver3"))
        #expect(dateStrings.contains("20150601"))
        #expect(dateStrings.contains("20150607"))
        #expect(exceptionTypes.contains(0))
    }

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

    @Test("decode trip from documented gtfs trip payload")
    func decodeTripPayload() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/trips/route/1
        let json = """
        {
          "route_id": "1",
          "service_id": "A:FÖLI_Kesä_2015_ver3",
          "trip_id": "0000null__1000generatedBlock",
          "trip_headsign": "Satama",
          "direction_id": 1,
          "block_id": "1000generatedBlock",
          "shape_id": "113",
          "wheelchair_accessible": 2
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.Trip.self, from: json)

        #expect(decoded.routeId == "1")
        #expect(decoded.serviceId == "A:FÖLI_Kesä_2015_ver3")
        #expect(decoded.tripId == "0000null__1000generatedBlock")
        #expect(decoded.wheelchairAccessible == 2)
    }

    @Test("decode stop time from stop-based payload variant")
    func decodeStopTimeForStopPayload() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/stop_times/stop/4
        let json = """
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
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.StopTime.self, from: json)

        #expect(decoded.tripId == "0000null__1901generatedBlock")
        #expect(decoded.stopId == nil)
        #expect(decoded.arrivalTime == "05:20:00")
        #expect(decoded.shapeDistTraveled == 0)
    }

    @Test("decode stop time from trip-based payload variant")
    func decodeStopTimeForTripPayload() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/stop_times/trip/%trip_id%
        let json = """
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
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.StopTime.self, from: json)

        #expect(decoded.tripId == nil)
        #expect(decoded.stopId == "1586")
        #expect(decoded.departureTime == "05:20:00")
        #expect(decoded.stopSequence == 0)
    }
}
