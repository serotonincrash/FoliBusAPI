import Foundation
import SwiftUI

// MARK: - Foli.Route Model
/// Information about a transit route (GTFS-compliant)
public extension Foli {
    struct Route: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// The unique identifier for the route (GTFS route_id)
        public let id: String
        /// Short name of the route (GTFS route_short_name) - often the line number
        public let shortName: String
        /// Full name of the route (GTFS route_long_name)
        public let longName: String
        /// Description of the route (GTFS route_desc)
        public let description: String?
        /// Route type (GTFS route_type) - 0=Tram, 3=Bus, etc.
        public let type: Int
        /// URL for the route (GTFS route_url)
        public let url: String?
        /// Color of the route in hex format (GTFS route_color)
        public let colorHex: String?
        /// Color of text on route in hex format (GTFS route_text_color)
        public let textColorHex: String?
        /// Agency that operates this route (GTFS agency_id)
        public let agencyId: String?

        /// Creates a route value using GTFS route fields.
        /// - Parameters:
        ///   - id: The GTFS `route_id` value.
        ///   - shortName: The GTFS `route_short_name`, often the line number.
        ///   - longName: The GTFS `route_long_name`.
        ///   - description: Optional GTFS `route_desc` value.
        ///   - type: The GTFS `route_type` integer.
        ///   - url: Optional GTFS `route_url` value.
        ///   - colorHex: Optional GTFS `route_color` hex string.
        ///   - textColorHex: Optional GTFS `route_text_color` hex string.
        ///   - agencyId: Optional GTFS `agency_id` value.
        public init(
            id: String,
            shortName: String,
            longName: String,
            description: String? = nil,
            type: Int,
            url: String? = nil,
            colorHex: String? = nil,
            textColorHex: String? = nil,
            agencyId: String? = nil
        ) {
            self.id = id
            self.shortName = shortName
            self.longName = longName
            self.description = description
            self.type = type
            self.url = url
            self.colorHex = colorHex
            self.textColorHex = textColorHex
            self.agencyId = agencyId
        }

        enum CodingKeys: String, CodingKey {
            case id = "route_id"
            case shortName = "route_short_name"
            case longName = "route_long_name"
            case description = "route_desc"
            case type = "route_type"
            case url = "route_url"
            case colorHex = "route_color"
            case textColorHex = "route_text_color"
            case agencyId = "agency_id"
        }

        // MARK: - Computed Properties

        /// Display name for the route
        public var displayName: String {
            if !longName.isEmpty {
                return longName
            }
            return shortName
        }

        /// Display name with short name and long name
        public var fullDisplayName: String {
            if longName.isEmpty {
                return shortName
            }
            return "\(shortName) - \(longName)"
        }

        /// Route color as a Color if available
        public var color: Color? {
            guard let hexColor = colorHex, !hexColor.isEmpty else {
                return nil
            }
            return Color(hex: hexColor)
        }

        /// Route text color if available
        public var textColor: Color? {
            guard let hexColor = textColorHex, !hexColor.isEmpty else {
                return nil
            }
            return Color(hex: hexColor)
        }

        /// Whether this is a bus route (route_type 3 or similar)
        public var isBus: Bool {
            return type == 3
        }

        /// Whether this is a tram route (route_type 0)
        public var isTram: Bool {
            return type == 0
        }
    }
}
