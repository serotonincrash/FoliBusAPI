import Foundation

/// Response from the alerts endpoint
public extension Foli {
    struct AlertsResponse: Codable, Sendable {
        /// Unix timestamp when the response was generated
        public let serverTime: TimeInterval
        /// System-wide global message (if any)
        public let globalMessage: Alert?
        /// Emergency message that should override all other messages
        public let emergencyMessage: Alert?
        /// List of trip cancellations
        public let cancellations: [TripCancellation]
        /// List of informational messages and alerts
        public let messages: [Alert]
        
        enum CodingKeys: String, CodingKey {
            case serverTime = "servertime"
            case globalMessage = "global_message"
            case emergencyMessage = "emergency_message"
            case cancellations
            case messages
        }
        
        public init(
            serverTime: TimeInterval,
            globalMessage: Alert? = nil,
            emergencyMessage: Alert? = nil,
            cancellations: [TripCancellation] = [],
            messages: [Alert] = []
        ) {
            self.serverTime = serverTime
            self.globalMessage = globalMessage
            self.emergencyMessage = emergencyMessage
            self.cancellations = cancellations
            self.messages = messages
        }
        
        // MARK: - Computed Properties
        
        /// Server time as Date
        public var serverDate: Date {
            Date(timeIntervalSince1970: serverTime)
        }
        
        /// All active messages (filtered by isActive)
        public var activeMessages: [Alert] {
            messages.filter { $0.isActive }
        }
        
        /// High priority messages (priority ≤ 100)
        public var highPriorityMessages: [Alert] {
            messages.filter { $0.isHighPriority }
        }
        
        /// Messages sorted by priority (ascending - lower = higher priority)
        public var messagesByPriority: [Alert] {
            messages.sorted { $0.priority < $1.priority }
        }
        
        /// Whether there is an emergency message active
        public var hasEmergency: Bool {
            emergencyMessage != nil
        }
        
        /// Whether there is a global message active
        public var hasGlobalMessage: Bool {
            globalMessage != nil
        }
        
        /// Get messages affecting a specific route
        public func messages(affectingRoute routeId: String) -> [Alert] {
            messages.filter { $0.affects(route: routeId) }
        }
        
        /// Get messages affecting a specific stop
        public func messages(affectingStop stopId: String) -> [Alert] {
            messages.filter { $0.affects(stop: stopId) }
        }
        
        /// Get cancellations affecting a specific stop
        public func cancellations(affectingStop stopId: String) -> [TripCancellation] {
            cancellations.filter { $0.affects(stop: stopId) }
        }
    }
}
