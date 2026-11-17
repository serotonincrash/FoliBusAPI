import Foundation
import Testing
@testable import FoliBusAPI

/// Föli's undocumented `__tripref` / `__routeref` / `__directionid` extensions.
@Suite("Trip Reference Decoding Tests")
struct TripRefDecodingTests {
    /// Trimmed from https://data.foli.fi/siri/sm/1902 (2026-11-17).
    static func arrivalPayload(extensions: String) -> Data {
        """
        {
          "sys": "SM",
          "status": "OK",
          "servertime": 1794930375,
          "result": [
            {
              "recordedattime": 1794930376,
              "lineref": "1",
              "originaimeddeparturetime": 1794929700,
              "destinationaimedarrivaltime": 1794932040,
              "monitored": true,
              "longitude": 22.26085,
              "latitude": 60.44713,
              "vehicleref": "80012",
              "destinationdisplay": "Lentoasema",
              "aimedarrivaltime": 1794930630,
              "expectedarrivaltime": 1794930651,
              "aimeddeparturetime": 1794930720,
              "expecteddeparturetime": 1794930720\(extensions)
            }
          ]
        }
        """.data(using: .utf8)!
    }

    /// Trimmed from https://data.foli.fi/siri/vm (2026-11-17).
    static func vehiclePayload(extensions: String) -> Data {
        """
        {
          "sys": "VM",
          "status": "OK",
          "servertime": 1794929576,
          "result": {
            "responsetimestamp": 1794929576,
            "producerref": "jlt",
            "responsemessageidentifier": "jlt-20220",
            "status": true,
            "moredata": false,
            "vehicles": {
              "80245": {
                "recordedattime": 1794929574,
                "validuntiltime": 1794929634,
                "lineref": "8",
                "directionref": "1",
                "publishedlinename": "8",
                "operatorref": "8",
                "originaimeddeparturetime": 1794928800,
                "destinationaimedarrivaltime": 1794931500,
                "monitored": true,
                "incongestion": false,
                "inpanic": false,
                "longitude": 22.25,
                "latitude": 60.45,
                "vehicleref": "80245"\(extensions)
              }
            }
          }
        }
        """.data(using: .utf8)!
    }

    @Test("arrival decodes Föli trip, route and direction references")
    func arrivalDecodesRefs() throws {
        let json = Self.arrivalPayload(extensions: """
        ,
              "__tripref": "00012308__1001060110",
              "__routeref": "1",
              "__directionid": "1"
        """)
        let arrival = try #require(try JSONDecoder().decode(Foli.ArrivalResponse.self, from: json).result.first)

        #expect(arrival.gtfsTripId == "00012308__1001060110")
        #expect(arrival.gtfsRouteId == "1")
        #expect(arrival.gtfsDirectionId == 1)
        #expect(arrival.vehicleRef == "80012")
    }

    @Test("vehicle decodes Föli trip, route and direction references")
    func vehicleDecodesRefs() throws {
        let json = Self.vehiclePayload(extensions: """
        ,
                "__tripref": "00017019__1008090110",
                "__routeref": "16",
                "__directionid": "0"
        """)
        let response = try JSONDecoder().decode(Foli.VehicleMonitoringResponse.self, from: json)
        let vehicle = try #require(response.vehicles.first)

        #expect(vehicle.gtfsTripId == "00017019__1008090110")
        // The GTFS route id differs from the line number.
        #expect(vehicle.gtfsRouteId == "16")
        #expect(vehicle.lineRef == "8")
        #expect(vehicle.gtfsDirectionId == 0)
    }

    @Test("references are nil when Föli omits them")
    func missingRefsDecodeAsNil() throws {
        let arrival = try #require(
            try JSONDecoder().decode(Foli.ArrivalResponse.self, from: Self.arrivalPayload(extensions: "")).result.first
        )
        let vehicle = try #require(
            try JSONDecoder().decode(Foli.VehicleMonitoringResponse.self, from: Self.vehiclePayload(extensions: "")).vehicles.first
        )

        #expect(arrival.gtfsTripId == nil && arrival.gtfsRouteId == nil && arrival.gtfsDirectionId == nil)
        #expect(vehicle.gtfsTripId == nil && vehicle.gtfsRouteId == nil && vehicle.gtfsDirectionId == nil)
    }

    @Test("numeric references decode instead of failing the record")
    func numericRefsDecode() throws {
        let json = Self.vehiclePayload(extensions: """
        ,
                "__tripref": 12345,
                "__routeref": 16,
                "__directionid": 1
        """)
        let vehicle = try #require(try JSONDecoder().decode(Foli.VehicleMonitoringResponse.self, from: json).vehicles.first)

        #expect(vehicle.gtfsTripId == "12345")
        #expect(vehicle.gtfsRouteId == "16")
        #expect(vehicle.gtfsDirectionId == 1)
    }

    @Test("references survive the memberwise init and an encode/decode round trip")
    func memberwiseAndRoundTrip() throws {
        let vehicle = Foli.VehicleLocation(
            recordedAtTime: 1, validUntilTime: 2, lineRef: "8", directionRef: "1",
            publishedLineName: "8", operatorRef: "8", monitored: true,
            inCongestion: false, inPanic: false, vehicleRef: "80245",
            gtfsTripId: "t1", gtfsRouteId: "16", gtfsDirectionId: 0
        )
        let decoded = try JSONDecoder().decode(Foli.VehicleLocation.self, from: JSONEncoder().encode(vehicle))

        #expect(decoded == vehicle)
        #expect(decoded.gtfsTripId == "t1")
        #expect(decoded.gtfsDirectionId == 0)

        let arrival = Foli.Arrival(
            recordedAtTime: 1, lineRef: "1", monitored: true,
            originAimedDepartureTime: 2, destinationAimedArrivalTime: 3, destinationDisplay: "X",
            aimedArrivalTime: 4, expectedArrivalTime: 4, aimedDepartureTime: 5, expectedDepartureTime: 5,
            gtfsTripId: "t2", gtfsRouteId: "1", gtfsDirectionId: 1
        )
        #expect(try JSONDecoder().decode(Foli.Arrival.self, from: JSONEncoder().encode(arrival)) == arrival)
    }
}

@Suite("Arrival vehicle reference")
struct ArrivalVehicleRefTests {
    @Test("unmonitored arrivals have no vehicle reference")
    func unmonitoredArrivalHasNoVehicleRef() throws {
        let json = """
        {"sys":"SM","status":"OK","servertime":1794930375,"result":[{
          "recordedattime":1794930376,"lineref":"1","originaimeddeparturetime":1794929700,
          "destinationaimedarrivaltime":1794932040,"monitored":false,"destinationdisplay":"Lentoasema",
          "aimedarrivaltime":1794930630,"expectedarrivaltime":1794930630,
          "aimeddeparturetime":1794930720,"expecteddeparturetime":1794930720}]}
        """.data(using: .utf8)!
        let arrival = try #require(try JSONDecoder().decode(Foli.ArrivalResponse.self, from: json).result.first)
        #expect(arrival.vehicleRef == nil)
    }
}
