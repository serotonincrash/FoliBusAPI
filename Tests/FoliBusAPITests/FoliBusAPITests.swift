import Testing
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
        // Invalid: array instead of object
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
