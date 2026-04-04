import Foundation

/// Real-time transit service alert or announcement
public extension Foli {
    struct Alert: Codable, Sendable, Identifiable, Equatable {
        /// Unique message identifier
        public let messageId: Int
        /// Icon recommendation (e.g., "BUS", "BOAT", "BIKE", "NONE", or combinations like "BUS_BIKE")
        public let icon: String
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
        public let `repeat`: [[TimeInterval]]
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
        
        enum CodingKeys: String, CodingKey {
            case messageId = "message_id"
            case icon
            case cause
            case effect
            case header
            case message
            case information
            case translations
            case images
            case `repeat`
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
        
        public init(
            messageId: Int,
            icon: String,
            cause: String,
            effect: String,
            header: String? = nil,
            message: String,
            information: String? = nil,
            translations: [String: AlertTranslation]? = nil,
            images: [AlertImage]? = nil,
            repeat: [[TimeInterval]],
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
            self.repeat = `repeat`
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
        public func affects(route routeId: String) -> Bool {
            affectedRoutes.contains(routeId)
        }
        
        /// Whether this alert affects a specific stop
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
        public var activePeriods: [(start: Date, end: Date)] {
            `repeat`.compactMap { period in
                guard period.count == 2 else { return nil }
                return (Date(timeIntervalSince1970: period[0]), Date(timeIntervalSince1970: period[1]))
            }
        }
        
        /// Time until alert becomes active (or nil if already active or expired)
        public func timeUntilActive(from date: Date = Date()) -> TimeInterval? {
            let timestamp = date.timeIntervalSince1970
            for period in `repeat` where period.count == 2 {
                if timestamp < period[0] {
                    return period[0] - timestamp
                }
            }
            return nil
        }
        
        /// Time until alert expires (or nil if not active or already expired)
        public func timeUntilExpiry(from date: Date = Date()) -> TimeInterval? {
            let timestamp = date.timeIntervalSince1970
            for period in `repeat` where period.count == 2 {
                if timestamp >= period[0] && timestamp < period[1] {
                    return period[1] - timestamp
                }
            }
            return nil
        }
    }
    
    /// Translation of an alert in a specific language
    struct AlertTranslation: Codable, Sendable, Equatable {
        public let header: String?
        public let message: String
        public let information: String?
        
        public init(header: String? = nil, message: String, information: String? = nil) {
            self.header = header
            self.message = message
            self.information = information
        }
    }
    
    /// Image attached to an alert
    struct AlertImage: Codable, Sendable, Equatable {
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
