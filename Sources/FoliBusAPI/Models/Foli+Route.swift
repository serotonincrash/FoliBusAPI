import Foundation
import SwiftUI

// MARK: - Foli.Route Model
/// Information about a transit route (GTFS-compliant)
public extension Foli {
    
    struct Route: Codable, Sendable, Identifiable {
        
        /// The unique identifier for the route (GTFS route_id)
        public let id: String
        /// Short name of the route (GTFS route_short_name) - often the line number
        public let shortName: String
        /// Full name of the route (GTFS route_long_name)
        public let longName: String
        /// Description of the route (GTFS route_desc)
        public let routeDesc: String?
        /// Route type (GTFS route_type) - 0=Tram, 3=Bus, etc.
        public let routeType: Int
        /// URL for the route (GTFS route_url)
        public let routeUrl: String?
        /// Color of the route in hex format (GTFS route_color)
        public let routeColor: String?
        /// Color of text on route in hex format (GTFS route_text_color)
        public let routeTextColor: String?
        /// Agency that operates this route (GTFS agency_id)
        public let agencyId: String?
        
        public init(
            id: String,
            shortName: String,
            longName: String,
            routeDesc: String? = nil,
            routeType: Int,
            routeUrl: String? = nil,
            routeColor: String? = nil,
            routeTextColor: String? = nil,
            agencyId: String? = nil
        ) {
            self.id = id
            self.shortName = shortName
            self.longName = longName
            self.routeDesc = routeDesc
            self.routeType = routeType
            self.routeUrl = routeUrl
            self.routeColor = routeColor
            self.routeTextColor = routeTextColor
            self.agencyId = agencyId
        }
        
        enum CodingKeys: String, CodingKey {
            case id = "route_id"
            case shortName = "route_short_name"
            case longName = "route_long_name"
            case routeDesc = "route_desc"
            case routeType = "route_type"
            case routeUrl = "route_url"
            case routeColor = "route_color"
            case routeTextColor = "route_text_color"
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
            guard let hexColor = routeColor, !hexColor.isEmpty else {
                return nil
            }
            return Color(hex: hexColor)
        }
        
        /// Route text color if available
        public var textColor: Color? {
            guard let hexColor = routeTextColor, !hexColor.isEmpty else {
                return nil
            }
            return Color(hex: hexColor)
        }
        
        /// Whether this is a bus route (route_type 3 or similar)
        public var isBus: Bool {
            return routeType == 3
        }
        
        /// Whether this is a tram route (route_type 0)
        public var isTram: Bool {
            return routeType == 0
        }
    }
}

// MARK: - Route List Response
/// Response containing all known routes (GTFS routes.txt)
public struct FoliRouteList: Codable {
    /// Array of all routes
    public let routes: [Foli.Route]
    
    public init(routes: [Foli.Route]) {
        self.routes = routes
    }
    // MARK: - API Decoding Helper
    /// Helper struct to decode the API response format where route_type is a number
    struct APIRouteData: Codable {
        let route_id: String
        let route_short_name: String
        let route_long_name: String
        let route_desc: String?
        let route_type: Int
        let route_url: String?
        let route_color: String?
        let route_text_color: String?
        let agency_id: String?
    }
    
    /// Helper to decode an array of route dictionaries from the API
    /// The API returns an array of routes with route_id as a field, not as dictionary keys
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Foli.Route].self)
        
        self.routes = array.sorted { $0.id < $1.id }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let array = routes.map { route -> APIRouteData in
            APIRouteData(
                route_id: route.id,
                route_short_name: route.shortName,
                route_long_name: route.longName,
                route_desc: route.routeDesc,
                route_type: route.routeType,
                route_url: route.routeUrl,
                route_color: route.routeColor,
                route_text_color: route.routeTextColor,
                agency_id: route.agencyId
            )
        }
        try container.encode(array)
    }
}
