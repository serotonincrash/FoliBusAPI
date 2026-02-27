//
//  FoliTrip.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

public extension Foli {
    struct Trip: Codable, Sendable, Identifiable, Equatable {
        public let id = UUID()
        public let serviceId: String
        public let tripId: String
        public let tripHeadsign: String
        public let directionId: Int
        public let blockId: String
        public let shapeId: String
        public let wheelchairAccessible: Int
        public let bikesAllowed: Int
        
        public enum CodingKeys: String, CodingKey {
            case serviceId = "service_id"
            case tripId = "trip_id"
            case tripHeadsign = "trip_headsign"
            case directionId = "direction_id"
            case blockId = "block_id"
            case shapeId = "shape_id"
            case wheelchairAccessible = "wheelchair_accessible"
            case bikesAllowed = "bikes_allowed"
        }
    }
}
