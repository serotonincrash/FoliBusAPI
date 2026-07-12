import Foundation

/// Real-time location and status information for a vehicle
///
/// - SeeAlso: ``Foli/Arrival``, ``Foli/Route``
public extension Foli {
    struct VehicleLocation: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Unix timestamp representing when this location was recorded
        public let recordedAtTime: TimeInterval
        /// Unix timestamp until which this data is considered valid
        public let validUntilTime: TimeInterval
        /// Distance along the route in meters
        public let linkDistance: Double?
        /// How far along the current link (segment between stops) the vehicle has progressed.
        /// SIRI `PercentageOfLink` — a percentage between 0 and 100 (or nil when unknown).
        public let segmentProgress: Double?
        /// Line reference (e.g., "14", "2A")
        public let lineRef: String
        /// Direction reference (typically "1" or "2")
        public let directionRef: String
        /// Published line name displayed to passengers
        public let publishedLineName: String
        /// Operator reference code
        public let operatorRef: String
        /// Reference code for the trip origin stop
        public let originRef: String?
        /// Name of the origin stop
        public let originName: String?
        /// Reference code for the trip destination stop
        public let destinationRef: String?
        /// Name of the destination stop
        public let destinationName: String?
        /// Planned departure time from origin (Unix timestamp)
        public let originAimedDepartureTime: TimeInterval?
        /// Planned arrival time at destination (Unix timestamp)
        public let destinationAimedArrivalTime: TimeInterval?
        /// Whether this vehicle is actively monitored
        public let monitored: Bool
        /// Whether the vehicle is currently in congestion
        public let inCongestion: Bool
        /// Whether the vehicle has triggered a panic alarm
        public let inPanic: Bool
        /// Longitude of vehicle location (WGS-84)
        public let longitude: Double
        /// Latitude of vehicle location (WGS-84)
        public let latitude: Double
        /// Delay from schedule as ISO 8601 duration string (e.g., "-PT13539S")
        public let delay: String?
        /// Unique vehicle reference identifier
        public let vehicleRef: String
        /// Array of previous stop calls made by this vehicle
        public let previousCalls: [StopCall]?
        /// Whether the vehicle is currently at a stop
        public let vehicleAtStop: Bool?
        /// Reference code for the next stop
        public let nextStopPointRef: String?
        /// Name of the next stop
        public let nextStopPointName: String?
        /// Display text for next stop destination
        public let nextDestinationDisplay: String?
        /// Planned arrival time at next stop (Unix timestamp)
        public let nextAimedArrivalTime: TimeInterval?
        /// Expected arrival time at next stop (Unix timestamp)
        public let nextExpectedArrivalTime: TimeInterval?
        /// Planned departure time from next stop (Unix timestamp)
        public let nextAimedDepartureTime: TimeInterval?
        /// Expected departure time from next stop (Unix timestamp)
        public let nextExpectedDepartureTime: TimeInterval?
        /// Array of onward stop calls for this vehicle
        public let onwardCalls: [StopCall]?

        /// Unique identifier for SwiftUI (uses vehicleRef)
        public var id: String { vehicleRef }

        /// Represents a stop call (previous or onward)
        public struct StopCall: Codable, Sendable, Equatable, Hashable {
            /// Reference code for the stop point
            public let stopPointRef: String
            /// Visit number for this stop in the trip sequence
            public let visitNumber: Int?
            /// Name of the stop
            public let stopPointName: String?
            /// Planned arrival time at this stop (Unix timestamp)
            public let aimedArrivalTime: TimeInterval?
            /// Expected arrival time at this stop (Unix timestamp)
            public let expectedArrivalTime: TimeInterval?
            /// Planned departure time from this stop (Unix timestamp)
            public let aimedDepartureTime: TimeInterval?
            /// Expected departure time from this stop (Unix timestamp)
            public let expectedDepartureTime: TimeInterval?

            private enum CodingKeys: String, CodingKey {
                case stopPointRef = "stoppointref"
                case visitNumber = "visitnumber"
                case stopPointName = "stoppointname"
                case aimedArrivalTime = "aimedarrivaltime"
                case expectedArrivalTime = "expectedarrivaltime"
                case aimedDepartureTime = "aimeddeparturetime"
                case expectedDepartureTime = "expecteddeparturetime"
            }

            /// Creates a new stop call record.
            ///
            /// - Parameters:
            ///   - stopPointRef: Reference code for the stop point.
            ///   - visitNumber: Visit number for this stop in the trip sequence.
            ///   - stopPointName: Name of the stop.
            ///   - aimedArrivalTime: Planned arrival time at this stop.
            ///   - expectedArrivalTime: Expected arrival time at this stop.
            ///   - aimedDepartureTime: Planned departure time from this stop.
            ///   - expectedDepartureTime: Expected departure time from this stop.
            public init(
                stopPointRef: String,
                visitNumber: Int? = nil,
                stopPointName: String? = nil,
                aimedArrivalTime: TimeInterval? = nil,
                expectedArrivalTime: TimeInterval? = nil,
                aimedDepartureTime: TimeInterval? = nil,
                expectedDepartureTime: TimeInterval? = nil
            ) {
                self.stopPointRef = stopPointRef
                self.visitNumber = visitNumber
                self.stopPointName = stopPointName
                self.aimedArrivalTime = aimedArrivalTime
                self.expectedArrivalTime = expectedArrivalTime
                self.aimedDepartureTime = aimedDepartureTime
                self.expectedDepartureTime = expectedDepartureTime
            }
        }

        private enum CodingKeys: String, CodingKey {
            case recordedAtTime = "recordedattime"
            case validUntilTime = "validuntiltime"
            case linkDistance = "linkdistance"
            case segmentProgress = "percentage"
            case lineRef = "lineref"
            case directionRef = "directionref"
            case publishedLineName = "publishedlinename"
            case operatorRef = "operatorref"
            case originRef = "originref"
            case originName = "originname"
            case destinationRef = "destinationref"
            case destinationName = "destinationname"
            case originAimedDepartureTime = "originaimeddeparturetime"
            case destinationAimedArrivalTime = "destinationaimedarrivaltime"
            case monitored
            case inCongestion = "incongestion"
            case inPanic = "inpanic"
            case longitude
            case latitude
            case delay
            case vehicleRef = "vehicleref"
            case previousCalls = "previouscalls"
            case vehicleAtStop = "vehicleatstop"
            case nextStopPointRef = "next_stoppointref"
            case nextStopPointName = "next_stoppointname"
            case nextDestinationDisplay = "next_destinationdisplay"
            case nextAimedArrivalTime = "next_aimedarrivaltime"
            case nextExpectedArrivalTime = "next_expectedarrivaltime"
            case nextAimedDepartureTime = "next_aimeddeparturetime"
            case nextExpectedDepartureTime = "next_expecteddeparturetime"
            case onwardCalls = "onwardcalls"
        }

        /// Creates a new vehicle location record.
        ///
        /// - Parameters:
        ///   - recordedAtTime: Unix timestamp when this location was recorded.
        ///   - validUntilTime: Unix timestamp until which this data is valid.
        ///   - linkDistance: Distance along the route in meters.
        ///   - segmentProgress: How far along the current link the vehicle has progressed (a percentage, 0–100).
        ///   - lineRef: Line reference (e.g., "14", "2A").
        ///   - directionRef: Direction reference (typically "1" or "2").
        ///   - publishedLineName: Published line name displayed to passengers.
        ///   - operatorRef: Operator reference code.
        ///   - originRef: Reference code for the trip origin stop.
        ///   - originName: Name of the origin stop.
        ///   - destinationRef: Reference code for the trip destination stop.
        ///   - destinationName: Name of the destination stop.
        ///   - originAimedDepartureTime: Planned departure time from origin.
        ///   - destinationAimedArrivalTime: Planned arrival time at destination.
        ///   - monitored: Whether this vehicle is actively monitored.
        ///   - inCongestion: Whether the vehicle is currently in congestion.
        ///   - inPanic: Whether the vehicle has triggered a panic alarm.
        ///   - longitude: Longitude of vehicle location (WGS-84).
        ///   - latitude: Latitude of vehicle location (WGS-84).
        ///   - delay: Delay from schedule as ISO 8601 duration string.
        ///   - vehicleRef: Unique vehicle reference identifier.
        ///   - previousCalls: Array of previous stop calls made by this vehicle.
        ///   - vehicleAtStop: Whether the vehicle is currently at a stop.
        ///   - nextStopPointRef: Reference code for the next stop.
        ///   - nextStopPointName: Name of the next stop.
        ///   - nextDestinationDisplay: Display text for next stop destination.
        ///   - nextAimedArrivalTime: Planned arrival time at next stop.
        ///   - nextExpectedArrivalTime: Expected arrival time at next stop.
        ///   - nextAimedDepartureTime: Planned departure time from next stop.
        ///   - nextExpectedDepartureTime: Expected departure time from next stop.
        ///   - onwardCalls: Array of onward stop calls for this vehicle.
        public init(
            recordedAtTime: TimeInterval,
            validUntilTime: TimeInterval,
            linkDistance: Double? = nil,
            segmentProgress: Double? = nil,
            lineRef: String,
            directionRef: String,
            publishedLineName: String,
            operatorRef: String,
            originRef: String? = nil,
            originName: String? = nil,
            destinationRef: String? = nil,
            destinationName: String? = nil,
            originAimedDepartureTime: TimeInterval? = nil,
            destinationAimedArrivalTime: TimeInterval? = nil,
            monitored: Bool,
            inCongestion: Bool,
            inPanic: Bool,
            longitude: Double,
            latitude: Double,
            delay: String? = nil,
            vehicleRef: String,
            previousCalls: [StopCall]? = nil,
            vehicleAtStop: Bool? = nil,
            nextStopPointRef: String? = nil,
            nextStopPointName: String? = nil,
            nextDestinationDisplay: String? = nil,
            nextAimedArrivalTime: TimeInterval? = nil,
            nextExpectedArrivalTime: TimeInterval? = nil,
            nextAimedDepartureTime: TimeInterval? = nil,
            nextExpectedDepartureTime: TimeInterval? = nil,
            onwardCalls: [StopCall]? = nil
        ) {
            self.recordedAtTime = recordedAtTime
            self.validUntilTime = validUntilTime
            self.linkDistance = linkDistance
            self.segmentProgress = segmentProgress
            self.lineRef = lineRef
            self.directionRef = directionRef
            self.publishedLineName = publishedLineName
            self.operatorRef = operatorRef
            self.originRef = originRef
            self.originName = originName
            self.destinationRef = destinationRef
            self.destinationName = destinationName
            self.originAimedDepartureTime = originAimedDepartureTime
            self.destinationAimedArrivalTime = destinationAimedArrivalTime
            self.monitored = monitored
            self.inCongestion = inCongestion
            self.inPanic = inPanic
            self.longitude = longitude
            self.latitude = latitude
            self.delay = delay
            self.vehicleRef = vehicleRef
            self.previousCalls = previousCalls
            self.vehicleAtStop = vehicleAtStop
            self.nextStopPointRef = nextStopPointRef
            self.nextStopPointName = nextStopPointName
            self.nextDestinationDisplay = nextDestinationDisplay
            self.nextAimedArrivalTime = nextAimedArrivalTime
            self.nextExpectedArrivalTime = nextExpectedArrivalTime
            self.nextAimedDepartureTime = nextAimedDepartureTime
            self.nextExpectedDepartureTime = nextExpectedDepartureTime
            self.onwardCalls = onwardCalls
        }

        // MARK: - Computed Properties

        /// Convert recorded time to Date
        public var recordedDate: Date {
            Date(timeIntervalSince1970: recordedAtTime)
        }

        /// Convert valid until time to Date
        public var validUntilDate: Date {
            Date(timeIntervalSince1970: validUntilTime)
        }

        /// Location coordinates as Foli.Coordinate
        public var location: Foli.Coordinate {
            Foli.Coordinate(latitude: latitude, longitude: longitude)
        }

        /// Parse ISO 8601 duration delay into seconds
        /// For example: "-PT13539S" -> -13539.0 seconds
        /// - Complexity: O(L) where L is the length of the delay string.
        public var delayInSeconds: TimeInterval? {
            guard let delay = delay else { return nil }
            return parseISO8601Duration(delay)
        }

        /// Whether the vehicle is running late (positive delay)
        public var isLate: Bool {
            guard let delaySeconds = delayInSeconds else { return false }
            return delaySeconds > 0
        }

        /// Whether the vehicle is running early (negative delay)
        public var isEarly: Bool {
            guard let delaySeconds = delayInSeconds else { return false }
            return delaySeconds < 0
        }

        /// Whether the vehicle is on schedule
        public var isOnTime: Bool {
            guard let delaySeconds = delayInSeconds else { return true }
            return delaySeconds == 0
        }

        /// Parse ISO 8601 duration string (e.g., "PT15M" or "-PT13539S")
        private func parseISO8601Duration(_ duration: String) -> TimeInterval? {
            var durationString = duration
            let isNegative = durationString.hasPrefix("-")
            if isNegative {
                durationString.removeFirst()
            }

            guard durationString.hasPrefix("PT") else { return nil }
            durationString.removeFirst(2)

            var totalSeconds: TimeInterval = 0

            // Parse hours
            if let hIndex = durationString.firstIndex(of: "H") {
                let hoursStr = String(durationString[..<hIndex])
                if let hours = TimeInterval(hoursStr) {
                    totalSeconds += hours * 3600
                }
                durationString = String(durationString[durationString.index(after: hIndex)...])
            }

            // Parse minutes
            if let mIndex = durationString.firstIndex(of: "M") {
                let minutesStr = String(durationString[..<mIndex])
                if let minutes = TimeInterval(minutesStr) {
                    totalSeconds += minutes * 60
                }
                durationString = String(durationString[durationString.index(after: mIndex)...])
            }

            // Parse seconds
            if let sIndex = durationString.firstIndex(of: "S") {
                let secondsStr = String(durationString[..<sIndex])
                if let seconds = TimeInterval(secondsStr) {
                    totalSeconds += seconds
                }
            }

            return isNegative ? -totalSeconds : totalSeconds
        }

        /// Time until next stop arrival (if available)
        public func timeUntilNextStop(from date: Date = Date()) -> TimeInterval? {
            guard let nextExpectedArrival = nextExpectedArrivalTime else { return nil }
            return nextExpectedArrival - date.timeIntervalSince1970
        }

        /// Whether this vehicle data is still valid
        public func isValid(at date: Date = Date()) -> Bool {
            return date.timeIntervalSince1970 < validUntilTime
        }
    }
}
