import Foundation

/// Trip cancellation information
public extension Foli {
    struct TripCancellation: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Line reference (e.g., "2A")
        public let line: String
        /// Icon recommendation
        public let icon: String
        /// GTFS-RT cause code for the cancellation
        public let cause: String
        /// Planned departure time from origin
        public let departure: TimeInterval
        /// Stops affected by this cancellation with scheduled times
        public let stops: [CancelledStop]
        /// Priority for display ordering
        public let priority: Int
        
        public var id: String { "\(line)_\(departure)" }
        
        public init(
            line: String,
            icon: String,
            cause: String,
            departure: TimeInterval,
            stops: [CancelledStop],
            priority: Int
        ) {
            self.line = line
            self.icon = icon
            self.cause = cause
            self.departure = departure
            self.stops = stops
            self.priority = priority
        }
        
        // MARK: - Computed Properties
        
        /// Departure time as Date
        public var departureDate: Date {
            Date(timeIntervalSince1970: departure)
        }
        
        /// Currently active cancelled stops (isActive = true)
        /// - Complexity: O(N) where N is the number of cancelled stops.
        public var activeStops: [CancelledStop] {
            stops.filter { $0.isActive }
        }
        
        /// Whether this cancellation affects a specific stop
        /// - Complexity: O(N) where N is the number of cancelled stops.
        public func affects(stop stopId: String) -> Bool {
            stops.contains { $0.stop == stopId }
        }
    }
    
    /// Stop affected by a trip cancellation
    struct CancelledStop: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Stop ID
        public let stop: String
        /// Scheduled arrival time at this stop
        public let arrival: TimeInterval
        /// Whether to display stop-specific alert now
        public let isActive: Bool
        
        public var id: String { stop }
        
        private enum CodingKeys: String, CodingKey {
            case stop
            case arrival
            case isActive = "isactive"
        }
        
        public init(stop: String, arrival: TimeInterval, isActive: Bool) {
            self.stop = stop
            self.arrival = arrival
            self.isActive = isActive
        }
        
        /// Arrival time as Date
        public var arrivalDate: Date {
            Date(timeIntervalSince1970: arrival)
        }
    }
}
