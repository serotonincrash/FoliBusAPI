import Foundation


/// Information about a vehicle arrival or departure
public extension Foli {
    struct Arrival: Codable, Sendable, Identifiable {
        public let id = UUID()
        /// Unix timestamp representing the last update from the vehicle
        public let recordedAtTime: TimeInterval
        /// Line reference (e.g., "15", "61")
        public let lineRef: String
        /// True if the vehicle produces real-time information
        public let monitored: Bool
        /// Estimated latitude of the arriving vehicle (WGS-84)
        public let latitude: Double?
        /// Estimated longitude of the arriving vehicle (WGS-84)
        public let longitude: Double?
        /// Planned departure from origin of trip
        public let originAimedDepartureTime: TimeInterval
        /// Planned arrival to terminus
        public let destinationAimedArrivalTime: TimeInterval
        /// Display text on bus front plate
        public let destinationDisplay: String
        /// Planned arrival to this stop
        public let aimedArrivalTime: TimeInterval
        /// Estimated real arrival time to this stop
        public let expectedArrivalTime: TimeInterval
        /// Planned departure from this stop
        public let aimedDepartureTime: TimeInterval
        /// Estimated real departure time from this stop
        public let expectedDepartureTime: TimeInterval
        /// Delay in seconds (optional, may not always be present)
        public let delay: Int?
        
        public init(
            recordedAtTime: TimeInterval,
            lineRef: String,
            monitored: Bool,
            latitude: Double? = nil,
            longitude: Double? = nil,
            originAimedDepartureTime: TimeInterval,
            destinationAimedArrivalTime: TimeInterval,
            destinationDisplay: String,
            aimedArrivalTime: TimeInterval,
            expectedArrivalTime: TimeInterval,
            aimedDepartureTime: TimeInterval,
            expectedDepartureTime: TimeInterval,
            delay: Int? = nil
        ) {
            self.recordedAtTime = recordedAtTime
            self.lineRef = lineRef
            self.monitored = monitored
            self.latitude = latitude
            self.longitude = longitude
            self.originAimedDepartureTime = originAimedDepartureTime
            self.destinationAimedArrivalTime = destinationAimedArrivalTime
            self.destinationDisplay = destinationDisplay
            self.aimedArrivalTime = aimedArrivalTime
            self.expectedArrivalTime = expectedArrivalTime
            self.aimedDepartureTime = aimedDepartureTime
            self.expectedDepartureTime = expectedDepartureTime
            self.delay = delay
        }
        
        enum CodingKeys: String, CodingKey {
            case recordedAtTime = "recordedattime"
            case lineRef = "lineref"
            case monitored
            case latitude
            case longitude
            case originAimedDepartureTime = "originaimeddeparturetime"
            case destinationAimedArrivalTime = "destinationaimedarrivaltime"
            case destinationDisplay = "destinationdisplay"
            case aimedArrivalTime = "aimedarrivaltime"
            case expectedArrivalTime = "expectedarrivaltime"
            case aimedDepartureTime = "aimeddeparturetime"
            case expectedDepartureTime = "expecteddeparturetime"
            case delay
        }
        
        // MARK: - Computed Properties
        
        /// Convert recorded time to Date
        public var recordedDate: Date {
            return Date(timeIntervalSince1970: recordedAtTime)
        }
        
        /// Convert aimed arrival time to Date
        public var aimedArrivalDate: Date {
            return Date(timeIntervalSince1970: aimedArrivalTime)
        }
        
        /// Convert expected arrival time to Date
        public var expectedArrivalDate: Date {
            return Date(timeIntervalSince1970: expectedArrivalTime)
        }
        
        /// Convert aimed departure time to Date
        public var aimedDepartureDate: Date {
            return Date(timeIntervalSince1970: aimedDepartureTime)
        }
        
        /// Convert expected departure time to Date
        public var expectedDepartureDate: Date {
            return Date(timeIntervalSince1970: expectedDepartureTime)
        }
        
        /// Arrival delay in seconds (calculated if not provided)
        public var arrivalDelay: TimeInterval {
            return expectedArrivalTime - aimedArrivalTime
        }
        
        /// Whether the vehicle is late (positive delay)
        public var isLate: Bool {
            return arrivalDelay > 0
        }
        
        /// Whether the vehicle is early (negative delay)
        public var isEarly: Bool {
            return arrivalDelay < 0
        }
        
        /// Whether the vehicle is on time
        public var isOnTime: Bool {
            return arrivalDelay == 0
        }
        
        /// Time until arrival from now
        public func timeUntilArrival(from date: Date = Date()) -> TimeInterval {
            return expectedArrivalTime - date.timeIntervalSince1970
        }
        
        /// Formatted time until arrival (e.g., "5 min")
        public func formattedTimeUntilArrival(from date: Date = Date()) -> String {
            let seconds = timeUntilArrival(from: date)
            let minutes = Int(seconds / 60)
            
            if minutes <= 0 {
                return "Due"
            } else if minutes < 60 {
                return "\(minutes) min"
            } else {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                if remainingMinutes > 0 {
                    return "\(hours)h \(remainingMinutes)m"
                } else {
                    return "\(hours)h"
                }
            }
        }
        
        /// Location coordinates if available
        public var location: CLLocationCoordinate2D? {
            guard let lat = latitude, let lon = longitude else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

// MARK: - Stop Monitoring Response
/// Response from the stop monitoring endpoint
/// 
public struct FoliArrivalResponse: Codable, Sendable {
    /// System identifier ("SM" for stop monitoring)
    public let sys: String
    /// Status of the response ("OK" or "NO_SIRI_DATA")
    public let status: String
    /// Unix timestamp when the response was generated
    public let serverTime: TimeInterval
    /// Array of vehicle arrivals/departures in order of arrival
    public let result: [Foli.Arrival]
    
    public init(sys: String, status: String, serverTime: TimeInterval, result: [Foli.Arrival]) {
        self.sys = sys
        self.status = status
        self.serverTime = serverTime
        self.result = result
    }
    
    enum CodingKeys: String, CodingKey {
        case sys
        case status
        case serverTime = "servertime"
        case result
    }
    
    /// Computed property to check if the response is valid
    public var isValid: Bool {
        return status == "OK"
    }
    
    /// Convert server time to Date
    public var serverDate: Date {
        return Date(timeIntervalSince1970: serverTime)
    }
}

