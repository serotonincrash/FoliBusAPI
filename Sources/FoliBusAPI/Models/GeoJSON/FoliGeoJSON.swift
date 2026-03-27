import Foundation

/// GeoJSON data structures for geographic information
public extension Foli {
    /// A GeoJSON Feature Collection
    struct FeatureCollection: Codable, Sendable {
        public let type: String
        public let name: String?
        public let features: [Feature]
        
        public init(type: String = "FeatureCollection", name: String? = nil, features: [Feature]) {
            self.type = type
            self.name = name
            self.features = features
        }
    }
    
    /// A GeoJSON feature
    struct Feature: Codable, Sendable {
        public let type: String
        public let id: String?
        public let geometry: Geometry
        public let properties: FeatureProperties
        
        public init(type: String = "Feature", id: String? = nil, geometry: Geometry, properties: FeatureProperties) {
            self.type = type
            self.id = id
            self.geometry = geometry
            self.properties = properties
        }
        
        /// Extract coordinate from Point geometry
        public var coordinate: Coordinate? {
            guard case .point(let coords) = geometry, coords.count == 2 else { return nil }
            return Coordinate(latitude: coords[1], longitude: coords[0])
        }
    }
    
    /// GeoJSON geometry type
    enum Geometry: Codable, Sendable {
        case point([Double])
        case multiPolygon([[[[Double]]]])
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
    
    /// Feature properties
    struct FeatureProperties: Codable, Sendable {
        public let category: String?
        public let name: String?
        public let nameFi: String?
        public let nameSv: String?
        public let nameEn: String?
        public let popup: String?
        public let text: String?
        public let city: String?
        public let cityFi: String?
        public let citySv: String?
        public let address: String?
        public let addressFi: String?
        public let addressSv: String?
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
        
        /// Get localized name
        public func localizedName(language: String = "en") -> String? {
            switch language {
            case "fi": return nameFi ?? name
            case "sv": return nameSv ?? name
            default: return nameEn ?? name
            }
        }
    }
    
    /// Icon definition
    struct GeoJSONIcon: Codable, Sendable {
        public let id: String
        
        /// The SVG string for this icon.
        /// Note that the Föli API currently only sends the SVG for the *first* instance of that SVG. 
        public let svg: String?
        
        public init(id: String, svg: String? = nil) {
            self.id = id
            self.svg = svg
        }
    }
}
