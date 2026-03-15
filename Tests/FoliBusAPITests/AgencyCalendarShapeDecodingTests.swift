import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Agency, Calendar, and Shape Decoding Tests")
struct AgencyCalendarShapeDecodingTests {
    @Test("decodes agency list payload")
    func decodesAgencyList() throws {
        let payload = #"""
        [
          {
            "agency_id": "FOLI",
            "agency_name": "Foli",
            "agency_url": "https://www.foli.fi",
            "agency_timezone": "Europe/Helsinki",
            "agency_lang": "fi",
            "agency_phone": "+3581234567"
          }
        ]
        """#.data(using: .utf8)!

        let list = try JSONDecoder().decode(FoliAgencyList.self, from: payload)
        #expect(list.agencies.count == 1)
        #expect(list.agencies[0].id == "FOLI")
        #expect(list.agencies[0].agencyName == "Foli")
    }

    @Test("decodes calendar list payload")
    func decodesCalendarList() throws {
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

        let list = try JSONDecoder().decode(FoliCalendarList.self, from: payload)
        #expect(list.calendars.count == 1)
        #expect(list.calendars[0].id == "WKD")
        #expect(list.calendars[0].monday == true)
    }

    @Test("decodes documented shape points payload")
    func decodesShapePointList() throws {
        let payload = #"""
        [
          {
            "lat": 60.4518,
            "lon": 22.2666,
            "traveled": 2.4
          },
          {
            "lat": 60.4510,
            "lon": 22.2650,
            "traveled": 1.2
          }
        ]
        """#.data(using: .utf8)!

        let list = try JSONDecoder().decode(FoliShapePointList.self, from: payload)
        #expect(list.shapePoints.count == 2)
        #expect(list.shapePoints[0].shapePtSequence == 1)
        #expect(list.shapePoints[0].shapeDistTraveled == 2.4)
        #expect(list.shapePoints[1].shapePtSequence == 2)
    }
}
