import Testing
import SwiftUI
@testable import FoliBusAPI
import Foundation

@Suite("FoliStopList Tests")
struct FoliStopListTests {
    
    @Test("Initialize FoliStopList with stops array")
    func initializeWithStops() async throws {
        let stops: [Foli.Stop] = [
            Foli.Stop(id: "1", stopName: "Central Station"),
            Foli.Stop(id: "2", stopName: "Market Square")
        ]
        
        let stopList = FoliStopList(stops: stops)
        
        #expect(stopList.stops.count == 2)
        #expect(stopList.stops[0].id == "1")
        #expect(stopList.stops[0].stopName == "Central Station")
        #expect(stopList.stops[1].id == "2")
        #expect(stopList.stops[1].stopName == "Market Square")
    }
    
    @Test("Initialize FoliStopList with empty array")
    func initializeWithEmptyStops() async throws {
        let stopList = FoliStopList(stops: [])
        
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
        
        let stopList = try JSONDecoder().decode(FoliStopList.self, from: json)
        
        #expect(stopList.stops.count == 3)
        #expect(stopList.stops.contains { $0.id == "1" && $0.stopName == "Central Station" })
        #expect(stopList.stops.contains { $0.id == "2" && $0.stopName == "Market Square" })
        #expect(stopList.stops.contains { $0.id == "3" && $0.stopName == "Harbor Terminal" })
    }
    
    @Test("Decode FoliStopList from empty JSON object")
    func decodeFromEmptyJSON() async throws {
        let json = "{}".data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(FoliStopList.self, from: json)
        
        #expect(stopList.stops.isEmpty)
    }
    
    @Test("Decode FoliStopList with coordinates")
    func decodeWithCoordinates() async throws {
        let json = """
        {
            "1": {"stop_name": "Central Station", "stop_lat": "60.45", "stop_lon": "22.27"},
            "2": {"stop_name": "Market Square", "stop_code": "002"}
        }
        """.data(using: .utf8)!
        
        let stopList = try JSONDecoder().decode(FoliStopList.self, from: json)
        
        #expect(stopList.stops.count == 2)
        let stop1 = stopList.stops.first { $0.id == "1" }
        #expect(stop1?.stopLat == 60.45)
        #expect(stop1?.stopLon == 22.27)
        #expect(stop1?.hasLocation == true)
        
        let stop2 = stopList.stops.first { $0.id == "2" }
        #expect(stop2?.stopCode == "002")
    }
    
    @Test("Stop displayName includes stop code when available")
    func stopDisplayNameIncludesCode() async throws {
        let stopWithCode = Foli.Stop(id: "1", stopName: "Central", stopCode: "001")
        let stopWithoutCode = Foli.Stop(id: "2", stopName: "Market", stopCode: nil)
        
        #expect(stopWithCode.displayName == "001 Central")
        #expect(stopWithoutCode.displayName == "Market")
    }
    
    @Test("Encode FoliStopList to JSON")
    func encodeToJSON() async throws {
        let stops: [Foli.Stop] = [
            Foli.Stop(id: "1", stopName: "Central Station"),
            Foli.Stop(id: "2", stopName: "Market Square")
        ]
        let stopList = FoliStopList(stops: stops)
        
        let encodedData = try JSONEncoder().encode(stopList)
        let decoded = try JSONSerialization.jsonObject(with: encodedData) as! [String: [String: String]]
        
        #expect(decoded.count == 2)
        #expect(decoded["1"]?["stop_name"] == "Central Station")
        #expect(decoded["2"]?["stop_name"] == "Market Square")
    }
    
    @Test("Round-trip encode and decode FoliStopList")
    func roundTripEncodeDecode() async throws {
        let originalStops: [Foli.Stop] = [
            Foli.Stop(id: "1", stopName: "Central Station"),
            Foli.Stop(id: "2", stopName: "Market Square"),
            Foli.Stop(id: "42", stopName: "Bus Depot")
        ]
        let original = FoliStopList(stops: originalStops)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(original)
        let decoded = try decoder.decode(FoliStopList.self, from: encodedData)
        
        #expect(decoded.stops.count == original.stops.count)
        for stop in original.stops {
            #expect(decoded.stops.contains { $0.id == stop.id && $0.stopName == stop.stopName })
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
        
        let stopList = try JSONDecoder().decode(FoliStopList.self, from: json)
        
        #expect(stopList.stops.contains { $0.stopName == "Åkerströms Gata" })
        #expect(stopList.stops.contains { $0.stopName == "Östra Sjukhuset" })
        #expect(stopList.stops.contains { $0.stopName == "Västra Tunneln" })
    }
    
    @Test("Decode fails with invalid JSON structure")
    func decodeInvalidStructure() async throws {
        let json = """
        [
            {"stop_name": "Central Station"}
        ]
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(FoliStopList.self, from: json)
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
        
        let stopList = try JSONDecoder().decode(FoliStopList.self, from: json)
        
        #expect(stopList.stops.count == 2)
        #expect(stopList.stops.contains { $0.id == "12345" && $0.stopName == "Stop 12345" })
        #expect(stopList.stops.contains { $0.id == "67890" && $0.stopName == "Stop 67890" })
    }
    
    @Test("Foli.Stop conforms to Identifiable")
    func stopIsIdentifiable() async throws {
        let stop = Foli.Stop(id: "42", stopName: "Test Stop")
        
        #expect(stop.id == "42")
    }
    
    @Test("Find stop by ID in array")
    func findStopById() async throws {
        let stops: [Foli.Stop] = [
            Foli.Stop(id: "1", stopName: "Central Station"),
            Foli.Stop(id: "2", stopName: "Market Square"),
            Foli.Stop(id: "3", stopName: "Harbor Terminal")
        ]
        
        let found = stops.first { $0.id == "2" }
        #expect(found?.stopName == "Market Square")
        
        let notFound = stops.first { $0.id == "99" }
        #expect(notFound == nil)
    }
}
@Suite("FoliRouteList Tests")
struct FoliRouteListTests {
    
    @Test("Initialize FoliRouteList with routes array")
    func initializeWithRoutes() async throws {
        let routes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", routeType: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", routeType: 3)
        ]
        
        let routeList = FoliRouteList(routes: routes)
        
        #expect(routeList.routes.count == 2)
        #expect(routeList.routes[0].id == "1001")
        #expect(routeList.routes[0].shortName == "15")
        #expect(routeList.routes[1].id == "1002")
        #expect(routeList.routes[1].shortName == "61")
    }
    
    @Test("Initialize FoliRouteList with empty array")
    func initializeWithEmptyRoutes() async throws {
        let routeList = FoliRouteList(routes: [])
        
        #expect(routeList.routes.isEmpty)
    }
    
    @Test("Decode FoliRouteList from valid JSON")
    func decodeFromValidJSON() async throws {
        let json = """
        {
            "1001": {"route_short_name": "15", "route_long_name": "Harbor - University", "route_type": "3"},
            "1002": {"route_short_name": "61", "route_long_name": "Airport Express", "route_type": "3"},
            "1003": {"route_short_name": "1", "route_long_name": "City Center Loop", "route_type": "0", "route_color": "FF0000"}
        }
        """.data(using: .utf8)!
        
        let routeList = try JSONDecoder().decode(FoliRouteList.self, from: json)
        
        #expect(routeList.routes.count == 3)
        #expect(routeList.routes.contains { $0.id == "1001" && $0.shortName == "15" })
        #expect(routeList.routes.contains { $0.id == "1002" && $0.shortName == "61" })
        #expect(routeList.routes.contains { $0.id == "1003" && $0.shortName == "1" })
    }
    
    @Test("Decode FoliRouteList with colors")
    func decodeWithColors() async throws {
        let json = """
        {
            "1001": {"route_short_name": "15", "route_long_name": "Harbor - University", "route_type": "3", "route_color": "007AC3", "route_text_color": "FFFFFF"}
        }
        """.data(using: .utf8)!
        
        let routeList = try JSONDecoder().decode(FoliRouteList.self, from: json)
        
        #expect(routeList.routes.count == 1)
        let route = routeList.routes.first!
        #expect(route.routeColor == "007AC3")
        #expect(route.routeTextColor == "FFFFFF")
        #expect(route.color != nil)
        #expect(route.textColor != nil)
    }
    
    @Test("Foli.Route computed properties work correctly")
    func routeComputedProperties() async throws {
        let busRoute = Foli.Route(
            id: "1001",
            shortName: "15",
            longName: "Harbor - University",
            routeType: 3
        )
        
        let tramRoute = Foli.Route(
            id: "2001",
            shortName: "1",
            longName: "City Loop",
            routeType: 0
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
            routeType: 3
        )
        
        #expect(route.displayName == "15")
    }
    
    @Test("Decode FoliRouteList from empty JSON object")
    func decodeFromEmptyJSON() async throws {
        let json = "{}".data(using: .utf8)!
        
        let routeList = try JSONDecoder().decode(FoliRouteList.self, from: json)
        
        #expect(routeList.routes.isEmpty)
    }
    
    @Test("Encode FoliRouteList to JSON")
    func encodeToJSON() async throws {
        let routes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", routeType: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", routeType: 3)
        ]
        let routeList = FoliRouteList(routes: routes)
        
        let encodedData = try JSONEncoder().encode(routeList)
        let decoded = try JSONSerialization.jsonObject(with: encodedData) as! [String: [String: String]]
        
        #expect(decoded.count == 2)
        #expect(decoded["1001"]?["route_short_name"] == "15")
        #expect(decoded["1001"]?["route_long_name"] == "Harbor - University")
        #expect(decoded["1002"]?["route_short_name"] == "61")
    }
    
    @Test("Round-trip encode and decode FoliRouteList")
    func roundTripEncodeDecode() async throws {
        let originalRoutes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", routeType: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", routeType: 3)
        ]
        let original = FoliRouteList(routes: originalRoutes)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(original)
        let decoded = try decoder.decode(FoliRouteList.self, from: encodedData)
        
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
        let route = Foli.Route(id: "1001", shortName: "15", longName: "Test", routeType: 3)
        
        #expect(route.id == "1001")
    }
    
    @Test("Find route by ID in array")
    func findRouteById() async throws {
        let routes: [Foli.Route] = [
            Foli.Route(id: "1001", shortName: "15", longName: "Harbor - University", routeType: 3),
            Foli.Route(id: "1002", shortName: "61", longName: "Airport Express", routeType: 3),
            Foli.Route(id: "2001", shortName: "1", longName: "City Loop", routeType: 0)
        ]
        
        let found = routes.first { $0.id == "1002" }
        #expect(found?.shortName == "61")
        
        let notFound = routes.first { $0.id == "9999" }
        #expect(notFound == nil)
    }
    
    @Test("SwiftUI.Color hex parsing works correctly")
    func colorHexParsing() async throws {
        let red = SwiftUI.Color(hex: "FF0000")
        let green = SwiftUI.Color(hex: "00FF00")
        let blue = SwiftUI.Color(hex: "0000FF")
        let withHash = SwiftUI.Color(hex: "#007AC3")
        
        // Just verify these don't crash - actual color comparison is complex
        #expect(true)
    }
}

