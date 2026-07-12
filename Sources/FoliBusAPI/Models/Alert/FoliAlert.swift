import Foundation

/// Real-time transit service alert or announcement
///
/// - SeeAlso: ``Foli/TripCancellation``, ``Foli/AlertCategory``
public extension Foli {
    struct Alert: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Unique message identifier
        public let messageId: Int
        /// Icon recommendation (e.g., "BUS", "BOAT", "BIKE", "NONE", or combinations like "BUS_BIKE")
        public let icon: Icon
        /// GTFS-RT cause code for the service disruption
        public let cause: String
        /// GTFS-RT effect code describing the impact
        public let effect: String
        /// Optional message header (max 64 characters)
        public let header: String?
        /// Main message content (max 300 characters) - works standalone
        public let message: String
        /// Additional information that complements the message
        public let information: String?
        /// Translations of header, message, and information in other languages
        public let translations: [String: AlertTranslation]?
        /// Images associated with this alert
        public let images: [AlertImage]?
        /// Time periods when this alert is valid [[start, end]]
        public let repeatIntervals: [[TimeInterval]]
        /// Whether the alert should be displayed now
        public let isActive: Bool
        /// Priority (lower number = higher priority, ≤100 considered important)
        public let priority: Int
        /// Route IDs from GTFS affected by this alert
        public let affectedRoutes: [String]
        /// Stop IDs from GTFS affected by this alert
        public let affectedStops: [String]
        /// Category tags for this alert
        public let categories: [String]
        
        /// Channels where alert is shown (internal use)
        public let channelWeb: Bool?
        public let channelStops: Bool?
        public let channelMobile: Bool?
        public let channelTicker: Bool?
        public let channelGtfsrt: Bool?
        
        public var id: Int { messageId }

        /// Icon recommendation for an alert.
        public enum Icon: RawRepresentable, Codable, Sendable, Equatable, Hashable {
            case bus
            case boat
            case bike
            case noIcon
            case busBike
            case unknown(String)

            public var rawValue: String {
                switch self {
                case .bus: return "BUS"
                case .boat: return "BOAT"
                case .bike: return "BIKE"
                case .noIcon: return "NONE"
                case .busBike: return "BUS_BIKE"
                case .unknown(let value): return value
                }
            }

            public init(rawValue: String) {
                switch rawValue {
                case "BUS": self = .bus
                case "BOAT": self = .boat
                case "BIKE": self = .bike
                case "NONE": self = .noIcon
                case "BUS_BIKE": self = .busBike
                default: self = .unknown(rawValue)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self.init(rawValue: rawValue)
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case messageId = "message_id"
            case icon
            case cause
            case effect
            case header
            case message
            case information
            case translations
            case images
            case repeatIntervals = "repeat"
            case isActive = "isactive"
            case priority
            case affectedRoutes = "affected_routes"
            case affectedStops = "affected_stops"
            case categories
            case channelWeb = "channel_web"
            case channelStops = "channel_stops"
            case channelMobile = "channel_mobile"
            case channelTicker = "channel_ticker"
            case channelGtfsrt = "channel_gtfsrt"
        }
        
        /// Creates a new alert with the specified properties.
        ///
        /// - Parameters:
        ///   - messageId: Unique identifier for the alert message.
        ///   - icon: Icon recommendation.
        ///   - cause: GTFS-RT cause code for the service disruption.
        ///   - effect: GTFS-RT effect code describing the impact.
        ///   - header: Optional message header (max 64 characters).
        ///   - message: Main message content (max 300 characters).
        ///   - information: Additional information that complements the message.
        ///   - translations: Translations of header, message, and information in other languages.
        ///   - images: Images associated with this alert.
        ///   - repeatIntervals: Time periods when this alert is valid as [[start, end]] Unix timestamps.
        ///   - isActive: Whether the alert should be displayed now.
        ///   - priority: Priority level (lower number = higher priority, ≤100 considered important).
        ///   - affectedRoutes: Route IDs from GTFS affected by this alert.
        ///   - affectedStops: Stop IDs from GTFS affected by this alert.
        ///   - categories: Category tags for this alert.
        ///   - channelWeb: Whether to show on web channel.
        ///   - channelStops: Whether to show on stops channel.
        ///   - channelMobile: Whether to show on mobile channel.
        ///   - channelTicker: Whether to show on ticker channel.
        ///   - channelGtfsrt: Whether to show on GTFS-RT channel.
        public init(
            messageId: Int,
            icon: Icon,
            cause: String,
            effect: String,
            header: String? = nil,
            message: String,
            information: String? = nil,
            translations: [String: AlertTranslation]? = nil,
            images: [AlertImage]? = nil,
            repeatIntervals: [[TimeInterval]],
            isActive: Bool,
            priority: Int,
            affectedRoutes: [String] = [],
            affectedStops: [String] = [],
            categories: [String] = [],
            channelWeb: Bool? = nil,
            channelStops: Bool? = nil,
            channelMobile: Bool? = nil,
            channelTicker: Bool? = nil,
            channelGtfsrt: Bool? = nil
        ) {
            self.messageId = messageId
            self.icon = icon
            self.cause = cause
            self.effect = effect
            self.header = header
            self.message = message
            self.information = information
            self.translations = translations
            self.images = images
            self.repeatIntervals = repeatIntervals
            self.isActive = isActive
            self.priority = priority
            self.affectedRoutes = affectedRoutes
            self.affectedStops = affectedStops
            self.categories = categories
            self.channelWeb = channelWeb
            self.channelStops = channelStops
            self.channelMobile = channelMobile
            self.channelTicker = channelTicker
            self.channelGtfsrt = channelGtfsrt
        }
        
        // MARK: - Computed Properties
        
        /// Whether this alert is considered high priority (≤100)
        public var isHighPriority: Bool {
            priority <= 100
        }
        
        /// Whether this alert affects a specific route
        /// - Complexity: O(N) where N is the number of affected routes.
        public func affects(route routeId: String) -> Bool {
            affectedRoutes.contains(routeId)
        }
        
        /// Whether this alert affects a specific stop
        /// - Complexity: O(N) where N is the number of affected stops.
        public func affects(stop stopId: String) -> Bool {
            affectedStops.contains(stopId)
        }
        
        /// Get localized content for a specific language
        public func localized(language: String) -> (header: String?, message: String, information: String?) {
            if let translation = translations?[language] {
                return (translation.header, translation.message, translation.information)
            }
            return (header, message, information)
        }
        
        /// Active time periods as Date ranges
        /// - Complexity: O(N) where N is the number of repeat periods.
        public var activePeriods: [(start: Date, end: Date)] {
            repeatIntervals.compactMap { period in
                guard period.count == 2 else { return nil }
                return (Date(timeIntervalSince1970: period[0]), Date(timeIntervalSince1970: period[1]))
            }
        }
        
        /// Time until alert becomes active (or nil if already active or expired)
        /// - Complexity: O(N) where N is the number of repeat periods.
        public func timeUntilActive(from date: Date = Date()) -> TimeInterval? {
            let timestamp = date.timeIntervalSince1970
            for period in repeatIntervals where period.count == 2 {
                if timestamp < period[0] {
                    return period[0] - timestamp
                }
            }
            return nil
        }
        
        /// Time until alert expires (or nil if not active or already expired)
        /// - Complexity: O(N) where N is the number of repeat periods.
        public func timeUntilExpiry(from date: Date = Date()) -> TimeInterval? {
            let timestamp = date.timeIntervalSince1970
            for period in repeatIntervals where period.count == 2 {
                if timestamp >= period[0] && timestamp < period[1] {
                    return period[1] - timestamp
                }
            }
            return nil
        }
    }
    
    /// Translation of an alert in a specific language
    struct AlertTranslation: Codable, Sendable, Equatable, Hashable {
        /// The alert header text for this language.
        public let header: String?
        /// The full alert message body for this language.
        public let message: String
        /// Additional informational text for this language.
        public let information: String?
        
        public init(header: String? = nil, message: String, information: String? = nil) {
            self.header = header
            self.message = message
            self.information = information
        }
    }
    
    /// Image attached to an alert
    struct AlertImage: Codable, Sendable, Equatable, Hashable {
        /// Protocol-relative URL (add "http:" or "https:" as needed)
        public let url: String
        /// MIME type (e.g., "image/png")
        public let type: String
        /// Optional image title
        public let title: String?
        
        public init(url: String, type: String, title: String? = nil) {
            self.url = url
            self.type = type
            self.title = title
        }
        
        /// Full URL with HTTPS protocol
        public var httpsURL: String {
            if url.hasPrefix("//") {
                return "https:\(url)"
            }
            return url
        }
    }
}
