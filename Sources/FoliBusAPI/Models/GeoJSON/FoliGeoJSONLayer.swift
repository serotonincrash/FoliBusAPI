import Foundation

/// GeoJSON layer information
public extension Foli {
    struct GeoJSONLayer: Codable, Sendable, Identifiable {
        public let name: LayerName
        public let url: String
        public let metadata: LayerMetadata
        
        public var id: String { name.en }
        
        public struct LayerName: Codable, Sendable {
            public let fi: String
            public let sv: String
            public let en: String
            
            public init(fi: String, sv: String, en: String) {
                self.fi = fi
                self.sv = sv
                self.en = en
            }
        }
        
        public struct LayerMetadata: Codable, Sendable {
            public let name: String
            public let popupContent: String
            public let textOnly: String
            
            public init(name: String, popupContent: String, textOnly: String) {
                self.name = name
                self.popupContent = popupContent
                self.textOnly = textOnly
            }
        }
        
        public init(name: LayerName, url: String, metadata: LayerMetadata) {
            self.name = name
            self.url = url
            self.metadata = metadata
        }
        
        /// Full URL with protocol
        public var httpsURL: String {
            if url.hasPrefix("//") {
                return "https:\(url)"
            }
            return url
        }
    }
    
    struct GeoJSONLayersResponse: Codable, Sendable {
        public let geojson: GeoJSONData
        
        public struct GeoJSONData: Codable, Sendable {
            public let layers: [GeoJSONLayer]
            
            public init(layers: [GeoJSONLayer]) {
                self.layers = layers
            }
        }
        
        public init(geojson: GeoJSONData) {
            self.geojson = geojson
        }
    }
}
