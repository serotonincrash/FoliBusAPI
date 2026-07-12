import Foundation

/// Response from the alerts endpoint
public extension Foli {
    struct AlertsResponse: Codable, Sendable, Equatable, Hashable {
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
        
        private enum CodingKeys: String, CodingKey {
            case serverTime = "servertime"
            case globalMessage = "global_message"
            case emergencyMessage = "emergency_message"
            case cancellations
            case messages
        }
        
        /// Creates a new alerts response.
        ///
        /// - Parameters:
        ///   - serverTime: Unix timestamp when the response was generated.
        ///   - globalMessage: System-wide global message, if any.
        ///   - emergencyMessage: Emergency message that should override all other messages.
        ///   - cancellations: List of trip cancellations.
        ///   - messages: List of informational messages and alerts.
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
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            serverTime = try container.decode(TimeInterval.self, forKey: .serverTime)
            cancellations = try container.decode([TripCancellation].self, forKey: .cancellations)
            messages = try container.decode([Alert].self, forKey: .messages)
            
            // Handle empty objects being returned as {} instead of null
            globalMessage = try Self.decodeOptionalAlert(from: container, forKey: .globalMessage)
            emergencyMessage = try Self.decodeOptionalAlert(from: container, forKey: .emergencyMessage)
        }
        
        /// Decode an optional Alert, treating empty objects as nil
        /// and rethrowing genuine decoding errors.
        private static func decodeOptionalAlert(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> Alert? {
            do {
                return try container.decodeIfPresent(Alert.self, forKey: key)
            } catch let error as DecodingError {
                // Expected: empty object {} from server
                // Decoding {} as Alert fails with keyNotFound (no message_id in empty dict),
                // dataCorrupted, or typeMismatch. Any other DecodingError is unexpected.
                switch error {
                case .keyNotFound, .dataCorrupted, .typeMismatch:
                    return nil
                default:
                    throw error
                }
            }
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
