import Foundation

// MARK: - GeoJSON Data Structures
/// GeoJSON data structures for geographic information.
///
/// These types conform to the GeoJSON specification (RFC 7946) and are used
/// to represent points of interest, service boundaries, and other geographic features.
public extension Foli {
    // MARK: - FeatureCollection
    /// A GeoJSON Feature Collection containing multiple features.
    ///
    /// Feature collections are the top-level response type for all geographic data endpoints.
    struct FeatureCollection: Codable, Sendable, Equatable, Hashable {
        /// GeoJSON type identifier (always "FeatureCollection").
        public let type: String
        /// Optional collection name.
        public let name: String?
        /// Array of geographic features in this collection.
        public let features: [Feature]
        
        /// Creates a feature collection.
        /// - Parameters:
        ///   - type: GeoJSON type identifier (defaults to "FeatureCollection").
        ///   - name: Optional collection name.
        ///   - features: Array of features.
        public init(type: String = "FeatureCollection", name: String? = nil, features: [Feature]) {
            self.type = type
            self.name = name
            self.features = features
        }
    }
    
    // MARK: - Feature
    /// A GeoJSON feature representing a single geographic entity.
    ///
    /// Features combine geometry (location/shape) with properties (metadata).
    struct Feature: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// GeoJSON type identifier (always "Feature").
        public let type: String
        /// Optional unique identifier for this feature.
        public let id: String?
        /// The feature's geographic shape (point, polygon, etc.).
        public let geometry: Geometry
        /// Metadata properties associated with this feature.
        public let properties: FeatureProperties
        
        /// Creates a feature.
        /// - Parameters:
        ///   - type: GeoJSON type identifier (defaults to "Feature").
        ///   - id: Optional feature identifier.
        ///   - geometry: Geographic shape.
        ///   - properties: Feature metadata.
        public init(type: String = "Feature", id: String? = nil, geometry: Geometry, properties: FeatureProperties) {
            self.type = type
            self.id = id
            self.geometry = geometry
            self.properties = properties
        }
        
        // MARK: - Computed Properties
        
        /// Extracts coordinate from Point geometry.
        ///
        /// Returns `nil` if the geometry is not a Point or has invalid coordinates.
        public var coordinate: Coordinate? {
            guard case .point(let coords) = geometry, coords.count == 2 else { return nil }
            return Coordinate(latitude: coords[1], longitude: coords[0])
        }
    }
    
    // MARK: - Geometry
    /// GeoJSON geometry type representing a geographic shape.
    ///
    /// Supports Point (single location), MultiPolygon (service areas), and
    /// MultiLineString (routes/boundaries) geometry types.
    enum Geometry: Codable, Sendable, Equatable, Hashable {
        /// Single point with [longitude, latitude] coordinates.
        case point([Double])
        /// Multiple polygons for complex area boundaries.
        case multiPolygon([[[[Double]]]])
        /// Multiple line strings for routes or linear boundaries.
        case multiLineString([[[Double]]])
        
        enum CodingKeys: String, CodingKey {
            case type
            case coordinates
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "Point":
                let coords = try container.decode([Double].self, forKey: .coordinates)
                self = .point(coords)
            case "MultiPolygon":
                let coords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
                self = .multiPolygon(coords)
            case "MultiLineString":
                let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
                self = .multiLineString(coords)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown geometry type: \(type)")
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .point(let coords):
                try container.encode("Point", forKey: .type)
                try container.encode(coords, forKey: .coordinates)
            case .multiPolygon(let coords):
                try container.encode("MultiPolygon", forKey: .type)
                try container.encode(coords, forKey: .coordinates)
            case .multiLineString(let coords):
                try container.encode("MultiLineString", forKey: .type)
                try container.encode(coords, forKey: .coordinates)
            }
        }
    }
    
    // MARK: - FeatureProperties
    /// Metadata properties associated with a GeoJSON feature.
    ///
    /// Properties vary by feature type but commonly include names in multiple languages,
    /// category information, addresses, and display icons.
    struct FeatureProperties: Codable, Sendable, Equatable, Hashable {
        /// Feature category (e.g., "bike_parking", "service_point").
        public let category: String?
        /// Default feature name.
        public let name: String?
        /// Finnish feature name.
        public let nameFi: String?
        /// Swedish feature name.
        public let nameSv: String?
        /// English feature name.
        public let nameEn: String?
        /// HTML content for map popups.
        public let popup: String?
        /// Plain text description.
        public let text: String?
        /// Default city name.
        public let city: String?
        /// Finnish city name.
        public let cityFi: String?
        /// Swedish city name.
        public let citySv: String?
        /// Default street address.
        public let address: String?
        /// Finnish street address.
        public let addressFi: String?
        /// Swedish street address.
        public let addressSv: String?
        /// Icon definition for map display.
        public let icon: GeoJSONIcon?
        
        enum CodingKeys: String, CodingKey {
            case category
            case name
            case nameFi = "name_fi"
            case nameSv = "name_sv"
            case nameEn = "name_en"
            case popup
            case text
            case city
            case cityFi = "city_fi"
            case citySv = "city_sv"
            case address
            case addressFi = "address_fi"
            case addressSv = "address_sv"
            case icon
        }
        
        /// Creates feature properties.
        /// - Parameters:
        ///   - category: Feature category.
        ///   - name: Default name.
        ///   - nameFi: Finnish name.
        ///   - nameSv: Swedish name.
        ///   - nameEn: English name.
        ///   - popup: Popup HTML content.
        ///   - text: Plain text description.
        ///   - city: Default city.
        ///   - cityFi: Finnish city name.
        ///   - citySv: Swedish city name.
        ///   - address: Default address.
        ///   - addressFi: Finnish address.
        ///   - addressSv: Swedish address.
        ///   - icon: Map icon definition.
        public init(
            category: String? = nil,
            name: String? = nil,
            nameFi: String? = nil,
            nameSv: String? = nil,
            nameEn: String? = nil,
            popup: String? = nil,
            text: String? = nil,
            city: String? = nil,
            cityFi: String? = nil,
            citySv: String? = nil,
            address: String? = nil,
            addressFi: String? = nil,
            addressSv: String? = nil,
            icon: GeoJSONIcon? = nil
        ) {
            self.category = category
            self.name = name
            self.nameFi = nameFi
            self.nameSv = nameSv
            self.nameEn = nameEn
            self.popup = popup
            self.text = text
            self.city = city
            self.cityFi = cityFi
            self.citySv = citySv
            self.address = address
            self.addressFi = addressFi
            self.addressSv = addressSv
            self.icon = icon
        }
        
        // MARK: - Computed Properties
        
        /// Returns the localized name for the specified language.
        /// - Parameter language: Language code ("fi", "sv", or "en"). Defaults to "en".
        /// - Returns: Localized name, falling back to default name if unavailable.
        public func localizedName(language: String = "en") -> String? {
            switch language {
            case "fi": return nameFi ?? name
            case "sv": return nameSv ?? name
            default: return nameEn ?? name
            }
        }
    }
    
    // MARK: - GeoJSONIcon
    /// Icon definition for GeoJSON feature display.
    ///
    /// Icons are identified by ID and may include an inline SVG definition.
    /// Note that the API only sends the SVG for the first occurrence of each icon ID.
    struct GeoJSONIcon: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Unique icon identifier.
        public let id: String
        
        /// The SVG markup for this icon.
        ///
        /// - Note: The Föli API only includes the SVG for the *first* instance of each icon ID
        ///   in a response. Subsequent features with the same icon ID will have `nil` here.
        public let svg: String?
        
        /// Creates an icon definition.
        /// - Parameters:
        ///   - id: Icon identifier.
        ///   - svg: Optional SVG markup.
        public init(id: String, svg: String? = nil) {
            self.id = id
            self.svg = svg
        }
    }
}
