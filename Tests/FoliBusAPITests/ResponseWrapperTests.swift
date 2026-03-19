import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Response Wrapper Tests")
struct ResponseWrapperTests {
    @Test("decode calendar dates list from documented dictionary shape")
    func decodeCalendarDatesList() throws {
        let json = """
        {
          "WKD": [
            { "date": "20240301", "exception_type": 1 },
            { "date": "20240302", "exception_type": 2 }
          ],
          "SAT": [
            { "date": "20240303", "exception_type": 1 }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.CalendarDatesList.self, from: json)
        let serviceIds = decoded.calendarDates.map(\.serviceId)
        let dateStrings = decoded.calendarDates.map(\.dateString)
        let exceptionTypes = decoded.calendarDates.map(\.exceptionType)

        #expect(decoded.calendarDates.count == 3)
        #expect(serviceIds.contains("WKD"))
        #expect(serviceIds.contains("SAT"))
        #expect(dateStrings.contains("20240301"))
        #expect(dateStrings.contains("20240303"))
        #expect(exceptionTypes.contains(1))
        #expect(exceptionTypes.contains(2))
    }

    @Test("decode arrival response from current siri contract")
    func decodeArrivalResponse() throws {
        let json = """
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
              "expecteddeparturetime": 1710000480
            }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.ArrivalResponse.self, from: json)
        let firstArrival = try #require(decoded.result.first)

        #expect(decoded.isValid)
        #expect(decoded.result.count == 1)
        #expect(firstArrival.lineRef == "1")
        #expect(firstArrival.destinationDisplay == "Satama")
        #expect(firstArrival.latitude == 60.4518)
    }

    @Test("decode trip from documented gtfs trip payload")
    func decodeTripPayload() throws {
        let json = """
        {
          "route_id": "10",
          "service_id": "WKD",
          "trip_id": "TRIP-10",
          "trip_headsign": "Airport",
          "direction_id": 1,
          "block_id": "BLOCK-10",
          "shape_id": "SHAPE-10",
          "wheelchair_accessible": 1,
          "bikes_allowed": 2
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.Trip.self, from: json)

        #expect(decoded.routeId == "10")
        #expect(decoded.serviceId == "WKD")
        #expect(decoded.tripId == "TRIP-10")
        #expect(decoded.bikesAllowed == 2)
    }

    @Test("decode stop time from stop-based payload variant")
    func decodeStopTimeForStopPayload() throws {
        let json = """
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
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.StopTime.self, from: json)

        #expect(decoded.tripId == "TRIP-1")
        #expect(decoded.stopId == nil)
        #expect(decoded.arrivalTime == "08:00:00")
        #expect(decoded.shapeDistTraveled == 123.5)
    }

    @Test("decode stop time from trip-based payload variant")
    func decodeStopTimeForTripPayload() throws {
        let json = """
        {
          "arrival_time": "08:00:00",
          "departure_time": "08:01:00",
          "stop_id": "1000",
          "stop_sequence": 1,
          "pickup_type": 0,
          "drop_off_type": 0,
          "timepoint": 1
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Foli.StopTime.self, from: json)

        #expect(decoded.tripId == nil)
        #expect(decoded.stopId == "1000")
        #expect(decoded.departureTime == "08:01:00")
        #expect(decoded.timepoint == 1)
    }
}
