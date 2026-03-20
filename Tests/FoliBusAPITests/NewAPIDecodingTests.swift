import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Vehicle Monitoring Decoding Tests")
struct VehicleMonitoringDecodingTests {
    @Test("decode vehicle monitoring response from documented VM payload")
    func decodeVMResponse() throws {
        let json = """
        {
            "sys": "VM",
            "status": "OK",
            "servertime": 1433246786,
            "result": {
                "responsetimestamp": 1433246783,
                "producerref": "jlt",
                "responsemessageidentifier": "western-62",
                "status": true,
                "moredata": false,
                "vehicles": {
                    "550011": {
                        "recordedattime": 1433246781,
                        "validuntiltime": 1433247381,
                        "linkdistance": 281,
                        "percentage": 41.28,
                        "lineref": "14",
                        "directionref": "1",
                        "publishedlinename": "14",
                        "operatorref": "55",
                        "originref": "246",
                        "originname": "Saramäki",
                        "destinationref": "395",
                        "destinationname": "Erikvalla",
                        "originaimeddeparturetime": 1433258100,
                        "destinationaimedarrivaltime": 1433261580,
                        "monitored": true,
                        "incongestion": false,
                        "inpanic": false,
                        "longitude": 22.240084,
                        "latitude": 60.431302,
                        "delay": "-PT13539S",
                        "vehicleref": "550011",
                        "vehicleatstop": false,
                        "next_stoppointref": "81",
                        "next_stoppointname": "Majakkaranta",
                        "next_destinationdisplay": "Erikvalla",
                        "next_aimedarrivaltime": 1433260320,
                        "next_expectedarrivaltime": 1433246507,
                        "next_aimeddeparturetime": 1433260380,
                        "next_expecteddeparturetime": 1433246567,
                        "previouscalls": [
                            {
                                "stoppointref": "80",
                                "visitnumber": 52,
                                "stoppointname": "Korppolaismäki",
                                "aimedarrivaltime": 1433260320,
                                "aimeddeparturetime": 1433260320
                            }
                        ],
                        "onwardcalls": [
                            {
                                "stoppointref": "82",
                                "visitnumber": 54,
                                "stoppointname": "Pihlajaniemi",
                                "aimedarrivaltime": 1433260380,
                                "expectedarrivaltime": 1433246841,
                                "aimeddeparturetime": 1433260440,
                                "expecteddeparturetime": 1433246901
                            }
                        ]
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(Foli.VehicleMonitoringResponse.self, from: json)

        #expect(response.isValid)
        #expect(response.serverTime == 1433246786)
        #expect(response.result.vehicles.count == 1)

        let vehicleEntry = try #require(response.result.vehicles.first)
        let vehicleId = vehicleEntry.key
        let vehicle = vehicleEntry.value
        #expect(vehicleId == "550011")
        #expect(vehicle.lineRef == "14")
        #expect(vehicle.monitored == true)
        #expect(vehicle.latitude == 60.431302)
        #expect(vehicle.longitude == 22.240084)
        #expect(vehicle.delay == "-PT13539S")
        #expect(vehicle.inCongestion == false)
        #expect(vehicle.nextStopPointRef == "81")
        #expect(vehicle.previousCalls?.count == 1)
        #expect(vehicle.onwardCalls?.count == 1)
    }

    @Test("VehicleLocation parses ISO 8601 duration delay")
    func parseDelayDuration() throws {
        let json = """
        {
            "recordedattime": 1433246781,
            "validuntiltime": 1433247381,
            "lineref": "14",
            "directionref": "1",
            "publishedlinename": "14",
            "operatorref": "55",
            "monitored": true,
            "incongestion": false,
            "inpanic": false,
            "longitude": 22.24,
            "latitude": 60.43,
            "delay": "-PT5M30S",
            "vehicleref": "550011"
        }
        """.data(using: .utf8)!

        let vehicle = try JSONDecoder().decode(Foli.VehicleLocation.self, from: json)

        #expect(vehicle.delayInSeconds == -330) // -5 minutes 30 seconds
        #expect(vehicle.isEarly == true)
        #expect(vehicle.isLate == false)
    }

    @Test("StopCall decodes previous and onward calls")
    func decodeStopCalls() throws {
        let json = """
        {
            "stoppointref": "82",
            "visitnumber": 54,
            "stoppointname": "Pihlajaniemi",
            "aimedarrivaltime": 1433260380,
            "expectedarrivaltime": 1433246841,
            "aimeddeparturetime": 1433260440,
            "expecteddeparturetime": 1433246901
        }
        """.data(using: .utf8)!

        let call = try JSONDecoder().decode(Foli.VehicleLocation.StopCall.self, from: json)

        #expect(call.stopPointRef == "82")
        #expect(call.visitNumber == 54)
        #expect(call.stopPointName == "Pihlajaniemi")
        #expect(call.aimedArrivalTime == 1433260380)
        #expect(call.expectedArrivalTime == 1433246841)
    }
}

@Suite("Alerts Decoding Tests")
struct AlertsDecodingTests {
    @Test("decode alerts response with messages and cancellations")
    func decodeAlertsResponse() throws {
        let json = """
        {
            "servertime": 1587723597,
            "global_message": {},
            "emergency_message": {},
            "cancellations": [
                {
                    "icon": "BUS",
                    "line": "2A",
                    "cause": "UNKNOWN_CAUSE",
                    "stops": [
                        {
                            "stop": "1651",
                            "arrival": 1587723300,
                            "isactive": true
                        }
                    ],
                    "priority": 1200,
                    "departure": 1587723300
                }
            ],
            "messages": [
                {
                    "icon": "BUS",
                    "cause": "OTHER_CAUSE",
                    "effect": "DETOUR",
                    "header": "Test header",
                    "message": "Test message content",
                    "information": "Additional info",
                    "isactive": true,
                    "priority": 1000,
                    "categories": ["ANNOUNCE"],
                    "message_id": 132390,
                    "images": [],
                    "repeat": [[1585741800, 1588194000]],
                    "translations": {},
                    "affected_stops": ["6275"],
                    "affected_routes": ["97"]
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(Foli.AlertsResponse.self, from: json)

        #expect(response.serverTime == 1587723597)
        #expect(response.cancellations.count == 1)
        #expect(response.messages.count == 1)

        let cancellation = response.cancellations[0]
        #expect(cancellation.line == "2A")
        #expect(cancellation.cause == "UNKNOWN_CAUSE")
        #expect(cancellation.stops.count == 1)
        #expect(cancellation.stops[0].isActive == true)

        let message = response.messages[0]
        #expect(message.header == "Test header")
        #expect(message.message == "Test message content")
        #expect(message.cause == "OTHER_CAUSE")
        #expect(message.effect == "DETOUR")
        #expect(message.isActive == true)
        #expect(message.affectedRoutes.contains("97"))
    }

    @Test("decode alert categories")
    func decodeAlertCategories() throws {
        let json = """
        [
            {
                "catid": 128853,
                "category": "TIMETABLE_CHANGES",
                "descr_fi": "Aikataulumuutokset",
                "descr_sv": "",
                "descr_en": "Timetable changes"
            },
            {
                "catid": 128852,
                "category": "TICKETS_AND_FARES",
                "descr_fi": "Liput ja hinnat",
                "descr_sv": "",
                "descr_en": "Ticket and fares"
            }
        ]
        """.data(using: .utf8)!

        let categories = try JSONDecoder().decode([Foli.AlertCategory].self, from: json)

        #expect(categories.count == 2)
        #expect(categories[0].category == "TIMETABLE_CHANGES")
        #expect(categories[0].descrEn == "Timetable changes")
        #expect(categories[1].category == "TICKETS_AND_FARES")
    }

    @Test("Alert isActive property from API response")
    func alertIsActiveProperty() throws {
        let now = Date().timeIntervalSince1970
        let json = """
        {
            "icon": "BUS",
            "cause": "OTHER_CAUSE",
            "effect": "DETOUR",
            "header": "",
            "message": "Active alert",
            "isactive": true,
            "priority": 1000,
            "categories": [],
            "images": [],
            "repeat": [[\(Int(now - 3600)), \(Int(now + 3600))]],
            "translations": {},
            "affected_stops": [],
            "affected_routes": [],
            "message_id": 12345
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(Foli.Alert.self, from: json)

        #expect(alert.isActive == true)
        #expect(alert.isHighPriority == false) // priority 1000 > 100
    }
}

@Suite("GeoJSON Decoding Tests")
struct GeoJSONDecodingTests {
    @Test("decode GeoJSON layers response")
    func decodeLayersResponse() throws {
        let json = """
        {
            "geojson": {
                "layers": [
                    {
                        "name": {
                            "fi": "Palvelupisteet",
                            "sv": "Servicekontorer",
                            "en": "Service points"
                        },
                        "url": "//data.foli.fi/geojson/poi/service_points",
                        "metadata": {
                            "name": "name",
                            "popupContent": "popup",
                            "textOnly": "text"
                        }
                    }
                ]
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(Foli.GeoJSONLayersResponse.self, from: json)

        #expect(response.geojson.layers.count == 1)
        let layer = response.geojson.layers[0]
        #expect(layer.name.en == "Service points")
        #expect(layer.name.fi == "Palvelupisteet")
        #expect(layer.url.contains("service_points"))
    }

    @Test("decode GeoJSON FeatureCollection with Point geometry")
    func decodeFeatureCollectionPoint() throws {
        let json = """
        {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "id": "poi_1008",
                    "geometry": {
                        "type": "Point",
                        "coordinates": [22.26296, 60.45065]
                    },
                    "properties": {
                        "category": "LOADING_POINT",
                        "name": "Stockmann",
                        "name_fi": "Stockmann",
                        "name_sv": "Stockmann",
                        "name_en": "Stockmann",
                        "popup": "<div class=\\"card-header-wrapper\\">\\n <span class=\\"h4\\">Stockmann</span>\\n <div class=\\"card-sub-header\\">Yliopistonkatu 22</div>\\n</div>\\n",
                        "text": "Stockmann\\nYliopistonkatu 22, 20100",
                        "city": "Turku",
                        "city_fi": "Turku",
                        "city_sv": "Åbo",
                        "address": "Yliopistonkatu 22",
                        "address_fi": "Yliopistonkatu 22",
                        "address_sv": "Yliopistonkatu 22",
                        "icon": {
                            "id": "icon_loading_point",
                            "svg": "<svg xmlns=\\"http://www.w3.org/2000/svg\\"\\n     width=\\"256\\" height=\\"256\\"></svg>"
                        }
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let collection = try JSONDecoder().decode(Foli.FeatureCollection.self, from: json)

        #expect(collection.features.count == 1)
        let feature = collection.features[0]
        #expect(feature.id == "poi_1008")
        #expect(feature.properties.name == "Stockmann")
        #expect(feature.properties.category == "LOADING_POINT")
        #expect(feature.properties.city == "Turku")
        #expect(feature.properties.address == "Yliopistonkatu 22")
        #expect(feature.properties.icon?.id == "icon_loading_point")

        guard case .point(let coords) = feature.geometry else {
            Issue.record("Expected Point geometry")
            return
        }
        #expect(coords[0] == 22.26296) // longitude
        #expect(coords[1] == 60.45065) // latitude

        // Test computed coordinate property
        let coordinate = feature.coordinate
        #expect(coordinate?.latitude == 60.45065)
        #expect(coordinate?.longitude == 22.26296)
    }

    @Test("decode GeoJSON MultiPolygon geometry for bounds")
    func decodeMultiPolygonGeometry() throws {
        let json = """
        {
            "type": "FeatureCollection",
            "name": "Foli-alue",
            "features": [
                {
                    "type": "Feature",
                    "properties": {
                        "name": "Föli-alue",
                        "name_fi": "Föli-alue",
                        "name_sv": "Föli-region",
                        "name_en": "Föli region"
                    },
                    "geometry": {
                        "type": "MultiPolygon",
                        "coordinates": [[[[21.55513, 60.35576], [21.55183, 60.35223], [21.55513, 60.35576]]]]
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let collection = try JSONDecoder().decode(Foli.FeatureCollection.self, from: json)

        #expect(collection.features.count == 1)
        let feature = collection.features[0]
        #expect(feature.id == nil) // Bounds features don't have IDs

        guard case .multiPolygon(let coords) = feature.geometry else {
            Issue.record("Expected MultiPolygon geometry")
            return
        }
        #expect(coords.count == 1) // One polygon
        #expect(coords[0][0].count == 3) // Three coordinate pairs in the ring
    }

    @Test("decode GeoJSON MultiLineString geometry")
    func decodeMultiLineStringGeometry() throws {
        let json = """
        {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "properties": {
                        "name": "Föli-alue",
                        "name_fi": "Föli-alue",
                        "name_sv": "Föli-region",
                        "name_en": "Föli region"
                    },
                    "geometry": {
                        "type": "MultiLineString",
                        "coordinates": [[[21.55, 60.35], [21.56, 60.36], [21.57, 60.37]]]
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let collection = try JSONDecoder().decode(Foli.FeatureCollection.self, from: json)
        let feature = collection.features[0]

        guard case .multiLineString(let coords) = feature.geometry else {
            Issue.record("Expected MultiLineString geometry")
            return
        }
        #expect(coords.count == 1)
        #expect(coords[0].count == 3)
    }
}
