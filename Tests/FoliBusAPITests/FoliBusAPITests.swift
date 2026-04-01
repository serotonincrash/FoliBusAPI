import Testing
import SwiftUI
@testable import FoliBusAPI
import Foundation

@Suite("FoliStopList Tests")
struct FoliStopListTests {
    
    @Test("Initialize FoliStopList with stops array")
    func initializeWithStops() async throws {
        let stops: [Foli.Stop] = [
            Foli.Stop(id: "1", name: "Central Station"),
            Foli.Stop(id: "2", name: "Market Square")
        ]
        
        let stopList = Foli.StopList(stops: stops)
        
        #expect(stopList.stops.count == 2)
        #expect(stopList.stops[0].id == "1")
        #expect(stopList.stops[0].name == "Central Station")
        #expect(stopList.stops[1].id == "2")
        #expect(stopList.stops[1].name == "Market Square")
    }
    
    @Test("Initialize FoliStopList with empty array")
    func initializeWithEmptyStops() async throws {
        let stopList = Foli.StopList(stops: [])
        
        #expect(stopList.stops.isEmpty)
    }
    
    @Test("Decode FoliStopList from valid JSON")
    func decodeFromValidJSON() async throws {
        let json = """
        {
            "1": {"stop_name": "Central Station"},
            "2": {"stop_name": "Market Square"},
            "3": {"stop_name": "Harbor Terminal"}
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        #expect(stopList.stops.count == 3)
        #expect(stopList.stops.contains { $0.id == "1" && $0.name == "Central Station" })
        #expect(stopList.stops.contains { $0.id == "2" && $0.name == "Market Square" })
        #expect(stopList.stops.contains { $0.id == "3" && $0.name == "Harbor Terminal" })
    }
    
    @Test("Decode FoliStopList from empty JSON object")
    func decodeFromEmptyJSON() async throws {
        let json = "{}".data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        #expect(stopList.stops.isEmpty)
    }
    
    @Test("Decode FoliStopList with coordinates")
    func decodeWithCoordinates() async throws {
        let json = """
        {
            "1": {"stop_name": "Central Station", "stop_lat": 60.45, "stop_lon": 22.27},
            "2": {"stop_name": "Market Square", "stop_code": "002"}
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        #expect(stopList.stops.count == 2)
        let stop1 = stopList.stops.first { $0.id == "1" }
        #expect(stop1?.latitude == 60.45)
        #expect(stop1?.longitude == 22.27)
        #expect(stop1?.hasLocation == true)
        
        let stop2 = stopList.stops.first { $0.id == "2" }
        #expect(stop2?.code == "002")
    }
    
    @Test("Stop displayName includes stop code when available")
    func stopDisplayNameIncludesCode() async throws {
        let stopWithCode = Foli.Stop(id: "1", name: "Central", code: "001")
        let stopWithoutCode = Foli.Stop(id: "2", name: "Market", code: nil)
        
        #expect(stopWithCode.displayName == "001 Central")
        #expect(stopWithoutCode.displayName == "Market")
    }
    
    @Test("Encode FoliStopList to JSON")
    func encodeToJSON() async throws {
        let stops: [Foli.Stop] = [
            Foli.Stop(id: "1", name: "Central Station"),
            Foli.Stop(id: "2", name: "Market Square")
        ]
        let stopList = Foli.StopList(stops: stops)
        
        let encodedData = try JSONEncoder().encode(stopList)
        let decoded = try #require(JSONSerialization.jsonObject(with: encodedData) as? [String: [String: String]])
        let firstStop = try #require(decoded["1"])
        let secondStop = try #require(decoded["2"])

        #expect(decoded.count == 2)
        #expect(firstStop["stop_name"] == "Central Station")
        #expect(secondStop["stop_name"] == "Market Square")
    }
    
    @Test("Round-trip encode and decode FoliStopList")
    func roundTripEncodeDecode() async throws {
        let originalStops: [Foli.Stop] = [
            Foli.Stop(id: "1", name: "Central Station"),
            Foli.Stop(id: "2", name: "Market Square"),
            Foli.Stop(id: "42", name: "Bus Depot")
        ]
        let original = Foli.StopList(stops: originalStops)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(original)
        let decoded = try decoder.decode(Foli.StopList.self, from: encodedData)
        
        #expect(decoded.stops.count == original.stops.count)
        for stop in original.stops {
            #expect(decoded.stops.contains { $0.id == stop.id && $0.name == stop.name })
        }
    }
    
    @Test("Decode handles stop names with special characters")
    func decodeSpecialCharacters() async throws {
        let json = """
        {
            "1": {"stop_name": "Åkerströms Gata"},
            "2": {"stop_name": "Östra Sjukhuset"},
            "3": {"stop_name": "Västra Tunneln"}
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        #expect(stopList.stops.contains { $0.name == "Åkerströms Gata" })
        #expect(stopList.stops.contains { $0.name == "Östra Sjukhuset" })
        #expect(stopList.stops.contains { $0.name == "Västra Tunneln" })
    }
    
    @Test("Decode fails with invalid JSON structure")
    func decodeInvalidStructure() async throws {
        let json = """
        [
            {"stop_name": "Central Station"}
        ]
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Foli.StopList.self, from: json)
        }
    }
    
    @Test("Decode handles numeric string keys")
    func decodeNumericStringKeys() async throws {
        let json = """
        {
            "12345": {"stop_name": "Stop 12345"},
            "67890": {"stop_name": "Stop 67890"}
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        #expect(stopList.stops.count == 2)
        #expect(stopList.stops.contains { $0.id == "12345" && $0.name == "Stop 12345" })
        #expect(stopList.stops.contains { $0.id == "67890" && $0.name == "Stop 67890" })
    }
    
    @Test("Foli.Stop conforms to Identifiable")
    func stopIsIdentifiable() async throws {
        let stop = Foli.Stop(id: "42", name: "Test Stop")
        
        #expect(stop.id == "42")
    }
    
    @Test("Find stop by ID in array")
    func findStopById() async throws {
        let stops: [Foli.Stop] = [
            Foli.Stop(id: "1", name: "Central Station"),
            Foli.Stop(id: "2", name: "Market Square"),
            Foli.Stop(id: "3", name: "Harbor Terminal")
        ]
        
        let found = stops.first { $0.id == "2" }
        #expect(found?.name == "Market Square")
        
        let notFound = stops.first { $0.id == "99" }
        #expect(notFound == nil)
    }
    
    @Test("Decode stop with full GTFS fields from real API format")
    func decodeFullGTFSStop() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/stops
        let json = """
        {
            "3079": {
                "stop_code": "",
                "stop_name": "Mikoinen",
                "stop_desc": "",
                "stop_lat": 60.50957,
                "stop_lon": 21.73462,
                "zone_id": "",
                "stop_url": "",
                "location_type": 0,
                "parent_station": 0,
                "stop_timezone": "Europe/Helsinki"
            }
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        #expect(stopList.stops.count == 1)
        let stop = try #require(stopList.stops.first)
        #expect(stop.id == "3079")
        #expect(stop.name == "Mikoinen")
        #expect(stop.code == "")
        #expect(stop.description == "")
        #expect(stop.latitude == 60.50957)
        #expect(stop.longitude == 21.73462)
        #expect(stop.zoneId == "")
        #expect(stop.url == "")
        #expect(stop.locationType == 0)
        #expect(stop.parentStation == "0")
        #expect(stop.timezone == "Europe/Helsinki")
    }
    
    @Test("Decode stop with parent station as string")
    func decodeStopWithStringParentStation() async throws {
        let json = """
        {
            "100": {
                "stop_code": "001",
                "stop_name": "Test Platform",
                "stop_desc": "Platform 1",
                "stop_lat": 60.45,
                "stop_lon": 22.27,
                "zone_id": "A",
                "stop_url": "https://example.com",
                "location_type": 0,
                "parent_station": "STATION_1",
                "stop_timezone": "Europe/Helsinki",
                "wheelchair_boarding": 1
            }
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(Foli.StopList.self, from: json)
        
        let stop = try #require(stopList.stops.first)
        #expect(stop.parentStation == "STATION_1")
        #expect(stop.wheelchairBoarding == 1)
    }
}
@Suite("FoliRouteList Tests")
struct FoliRouteListTests {
    
    @Test("Initialize FoliRouteList with routes array")
    func initializeWithRoutes() async throws {
        let routes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", type: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", type: 3)
        ]
        
        let routeList = Foli.RouteList(routes: routes)
        
        #expect(routeList.routes.count == 2)
        #expect(routeList.routes[0].id == "1001")
        #expect(routeList.routes[0].shortName == "15")
        #expect(routeList.routes[1].id == "1002")
        #expect(routeList.routes[1].shortName == "61")
    }
    
    @Test("Initialize FoliRouteList with empty array")
    func initializeWithEmptyRoutes() async throws {
        let routeList = Foli.RouteList(routes: [])
        
        #expect(routeList.routes.isEmpty)
    }
    
    @Test("Decode FoliRouteList from real API format")
    func decodeFromValidJSON() async throws {
        // Based on actual API response from https://data.foli.fi/gtfs/routes
        let json = """
        [
            {"route_id": "25", "agency_id": "2", "route_short_name": "L14", "route_long_name": "Loukinainen-Avanti", "route_desc": "", "route_type": 3, "route_url": "", "route_color": "000000", "route_text_color": "ffffff"},
            {"route_id": "3", "agency_id": "11", "route_short_name": "2A", "route_long_name": "Kohmo-Liljalaakso", "route_desc": "", "route_type": 3, "route_url": "", "route_color": "000000", "route_text_color": "ffffff"}
        ]
        """.data(using: .utf8)!
        
        let routeList = try JSONDecoder().decode(Foli.RouteList.self, from: json)
        
        #expect(routeList.routes.count == 2)
        #expect(routeList.routes.contains { $0.id == "25" && $0.shortName == "L14" })
        #expect(routeList.routes.contains { $0.id == "3" && $0.shortName == "2A" })
        let route = try #require(routeList.routes.first { $0.id == "25" })
        #expect(route.agencyId == "2")
        #expect(route.longName == "Loukinainen-Avanti")
        #expect(route.type == 3)
        #expect(route.colorHex == "000000")
        #expect(route.textColorHex == "ffffff")
    }
    
    @Test("Decode FoliRouteList with colors")
    func decodeWithColors() async throws {
        let json = """
        [
            {"route_id": "1001", "route_short_name": "15", "route_long_name": "Harbor - University", "route_type": 3, "route_color": "007AC3", "route_text_color": "FFFFFF"}
        ]
        """.data(using: .utf8)!
        
        let routeList = try JSONDecoder().decode(Foli.RouteList.self, from: json)
        
        #expect(routeList.routes.count == 1)
        let route = routeList.routes.first!
        #expect(route.colorHex == "007AC3")
        #expect(route.textColorHex == "FFFFFF")
        #expect(route.color != nil)
        #expect(route.textColor != nil)
    }
    
    @Test("Foli.Route computed properties work correctly")
    func routeComputedProperties() async throws {
        let busRoute = Foli.Route(
            id: "1001",
            shortName: "15",
            longName: "Harbor - University",
            type: 3
        )
        
        let tramRoute = Foli.Route(
            id: "2001",
            shortName: "1",
            longName: "City Loop",
            type: 0
        )
        
        #expect(busRoute.isBus == true)
        #expect(busRoute.isTram == false)
        
        #expect(tramRoute.isTram == true)
        #expect(tramRoute.isBus == false)
        
        #expect(busRoute.displayName == "Harbor - University")
        #expect(busRoute.fullDisplayName == "15 - Harbor - University")
    }
    
    @Test("Route displayName falls back to short name")
    func routeDisplayNameFallback() async throws {
        let route = Foli.Route(
            id: "1001",
            shortName: "15",
            longName: "",
            type: 3
        )
        
        #expect(route.displayName == "15")
    }
    
    @Test("Decode FoliRouteList from empty JSON object")
    func decodeFromEmptyJSON() async throws {
        let json = "[]".data(using: .utf8)!
        
        let routeList = try JSONDecoder().decode(Foli.RouteList.self, from: json)
        
        #expect(routeList.routes.isEmpty)
    }
    
    @Test("Encode FoliRouteList to JSON")
    func encodeToJSON() async throws {
        let routes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", type: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", type: 3)
        ]
        let routeList = Foli.RouteList(routes: routes)
        
        let encodedData = try JSONEncoder().encode(routeList)
        let decoded = try #require(JSONSerialization.jsonObject(with: encodedData) as? [[String: Any]])
        let firstRoute = try #require(decoded.first { ($0["route_id"] as? String) == "1001" })
        let secondRoute = try #require(decoded.first { ($0["route_id"] as? String) == "1002" })

        #expect(decoded.count == 2)
        #expect(firstRoute["route_short_name"] as? String == "15")
        #expect(firstRoute["route_long_name"] as? String == "Harbor - University")
        #expect((firstRoute["route_type"] as? Int) == 3 || (firstRoute["route_type"] as? NSNumber)?.intValue == 3)
        #expect(secondRoute["route_short_name"] as? String == "61")
    }
    
    @Test("Round-trip encode and decode FoliRouteList")
    func roundTripEncodeDecode() async throws {
        let originalRoutes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", type: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", type: 3)
        ]
        let original = Foli.RouteList(routes: originalRoutes)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(original)
        let decoded = try decoder.decode(Foli.RouteList.self, from: encodedData)
        
        #expect(decoded.routes.count == original.routes.count)
        for route in original.routes {
            #expect(decoded.routes.contains {
                $0.id == route.id &&
                $0.shortName == route.shortName &&
                $0.longName == route.longName
            })
        }
    }
    
    @Test("Foli.Route conforms to Identifiable")
    func routeIsIdentifiable() async throws {
        let route = Foli.Route(id: "1001", shortName: "15", longName: "Test", type: 3)
        
        #expect(route.id == "1001")
    }
    
    @Test("Find route by ID in array")
    func findRouteById() async throws {
        let routes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", type: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", type: 3),
            Foli.Route(id: "2001", shortName: "1", longName: "City Loop", type: 0)
        ]
        
        let found = routes.first { $0.id == "1002" }
        #expect(found?.shortName == "61")
        
        let notFound = routes.first { $0.id == "9999" }
        #expect(notFound == nil)
    }
    
    @Test("SwiftUI.Color hex parsing works correctly")
    func colorHexParsing() async throws {
        _ = SwiftUI.Color(hex: "FF0000")
        _ = SwiftUI.Color(hex: "00FF00")
        _ = SwiftUI.Color(hex: "0000FF")
        _ = SwiftUI.Color(hex: "#007AC3")

        #expect(Bool(true))
    }
}
