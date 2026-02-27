//
//  FoliStopTime.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import Foundation

public extension Foli {
    struct StopTime: Codable, Sendable, Identifiable, Equatable {
        public let id = UUID()
        public let tripId: String
        public let arrivalTime: String
        public let departureTime: String
        public let stopId: String
        public let stopSequence: Int
        public let stopHeadsign: String?
        public let pickupType: Int?
        public let dropOffType: Int?
        public let shapeDistTraveled: Double?
        public let timepoint: Int?
        
        public enum CodingKeys: String, CodingKey {
            case tripId = "trip_id"
            case arrivalTime = "arrival_time"
            case departureTime = "departure_time"
            case stopId = "stop_id"
            case stopSequence = "stop_sequence"
            case stopHeadsign = "stop_headsign"
            case pickupType = "pickup_type"
            case dropOffType = "drop_off_type"
            case shapeDistTraveled = "shape_dist_traveled"
            case timepoint = "timepoint"
        }
    }
}
