import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Agency, Calendar, and Shape Decoding Tests")
struct AgencyCalendarShapeDecodingTests {
    @Test("decodes agency list from real API format")
    func decodesAgencyList() throws {
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
          },
          {
            "agency_id": "8",
            "agency_name": "TUKL",
            "agency_url": "https://www.google.fi/",
            "agency_timezone": "Europe/Helsinki",
            "agency_lang": "  ",
            "agency_phone": "",
            "agency_fare_url": null
          }
        ]
        """#.data(using: .utf8)!

        let list = try JSONDecoder().decode(Foli.AgencyList.self, from: payload)
        #expect(list.agencies.count == 2)
        #expect(list.agencies[0].id == "11")
        #expect(list.agencies[0].name == "SLA")
        #expect(list.agencies[0].agencyTimezone == "Europe/Helsinki")
        #expect(list.agencies[0].agencyLang == "  ")
    }

    @Test("decodes calendar list from real API format")
    func decodesCalendarList() throws {
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
          },
          "S:FÖLI_Kesä_2015_ver3": {
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

        let list = try JSONDecoder().decode(Foli.CalendarList.self, from: payload)
        #expect(list.calendars.count == 2)
        #expect(list.calendars.contains { $0.id == "A:FÖLI_Kesä_2015_ver3" })
        #expect(list.calendars.contains { $0.id == "S:FÖLI_Kesä_2015_ver3" })
        let calendar = try #require(list.calendars.first { $0.id == "A:FÖLI_Kesä_2015_ver3" })
        #expect(calendar.monday == false)
        #expect(calendar.startDate == "20150601")
        #expect(calendar.endDate == "20150628")
    }

    @Test("decodes shape points from real API format")
    func decodesShapePointList() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/shapes/0_7
        let payload = #"""
        [
          {
            "lat": 60.51109,
            "lon": 22.27421,
            "traveled": 0
          },
          {
            "lat": 60.51109,
            "lon": 22.27422,
            "traveled": 0.60009
          },
          {
            "lat": 60.43491,
            "lon": 22.21961,
            "traveled": 13188.18374
          }
        ]
        """#.data(using: .utf8)!

        let list = try JSONDecoder().decode(Foli.ShapePointList.self, from: payload)
        #expect(list.shapePoints.count == 3)
        #expect(list.shapePoints[0].latitude == 60.51109)
        #expect(list.shapePoints[0].longitude == 22.27421)
        #expect(list.shapePoints[0].shapeDistTraveled == 0)
        #expect(list.shapePoints[0].sequence == 1)  // Generated sequence
        #expect(list.shapePoints[1].shapeDistTraveled == 0.60009)
        #expect(list.shapePoints[2].shapeDistTraveled == 13188.18374)
    }
    
    @Test("decode trip from real API format")
    func decodesTripFromAPI() throws {
        // Based on actual API response from 
        let payload = #"""
        [
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
        ]
        """#.data(using: .utf8)!

        let trips = try JSONDecoder().decode([Foli.Trip].self, from: payload)
        #expect(trips.count == 1)
        let trip = trips[0]
        #expect(trip.routeId == "1")
        #expect(trip.serviceId == "A:FÖLI_Kesä_2015_ver3")
        #expect(trip.tripHeadsign == "Satama")
        #expect(trip.directionId == 1)
        #expect(trip.blockId == "1000generatedBlock")
        #expect(trip.shapeId == "113")
        #expect(trip.wheelchairAccessible == 2)
    }
    
    @Test("decode stop time from stop-based API format")
    func decodesStopTimeFromStopAPI() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/stop_times/stop/%stop_id%
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

        let stopTimes = try JSONDecoder().decode([Foli.StopTime].self, from: payload)
        #expect(stopTimes.count == 1)
        let stopTime = stopTimes[0]
        #expect(stopTime.tripId == "0000null__1901generatedBlock")
        #expect(stopTime.arrivalTime == "05:20:00")
        #expect(stopTime.departureTime == "05:20:00")
        #expect(stopTime.stopSequence == 0)
        #expect(stopTime.pickupType == 0)
        #expect(stopTime.dropOffType == 0)
    }
    
    @Test("decode stop time from trip-based API format")
    func decodesStopTimeFromTripAPI() throws {
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
          },
          {
            "arrival_time": "05:48:00",
            "departure_time": "05:48:00",
            "stop_id": "1",
            "stop_sequence": 40,
            "stop_headsign": "",
            "pickup_type": 0,
            "drop_off_type": 0,
            "shape_dist_traveled": 13188.18374
          }
        ]
        """#.data(using: .utf8)!

        let stopTimes = try JSONDecoder().decode([Foli.StopTime].self, from: payload)
        #expect(stopTimes.count == 2)
        #expect(stopTimes[0].stopId == "1586")
        #expect(stopTimes[1].stopId == "1")
        #expect(stopTimes[1].stopSequence == 40)
    }
    
    @Test("decode calendar dates from real API format")
    func decodesCalendarDates() throws {
        // Based on actual API response from https://data.foli.fi/gtfs/calendar_dates
        let payload = #"""
        {
          "A:FÖLI_Kesä_2015_ver3": [
            {
              "date": "20150601",
              "exception_type": 0
            },
            {
              "date": "20150626",
              "exception_type": 0
            }
          ],
          "S:FÖLI_Kesä_2015_ver3": [
            {
              "date": "20150607",
              "exception_type": 0
            }
          ]
        }
        """#.data(using: .utf8)!

        let list = try JSONDecoder().decode(Foli.CalendarDatesList.self, from: payload)
        #expect(list.calendarDates.count == 3)  // Total across all service IDs
        let dateForA = list.calendarDates.filter { $0.serviceId == "A:FÖLI_Kesä_2015_ver3" }
        #expect(dateForA.count == 2)
        #expect(dateForA[0].dateString == "20150601")
        #expect(dateForA[0].exceptionType == 0)
    }
}
