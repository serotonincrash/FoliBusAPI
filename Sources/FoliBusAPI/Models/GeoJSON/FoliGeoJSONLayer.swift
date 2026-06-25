import Foundation

// MARK: - GeoJSON Layer Model
/// GeoJSON layer metadata from the Föli map data API.
///
/// Layers represent different categories of geographic data available from the API,
/// such as points of interest, service boundaries, or bike parking locations.
public extension Foli {
    struct GeoJSONLayer: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Localized layer names in Finnish, Swedish, and English.
        public let name: LayerName
        /// Relative URL path to fetch this layer's GeoJSON data.
        public let url: String
        /// Metadata describing how to display feature properties.
        public let metadata: LayerMetadata
        
        /// Unique identifier using the English layer name.
        public var id: String { name.en }
        
        // MARK: - LayerName
        /// Localized layer name in three languages.
        public struct LayerName: Codable, Sendable, Equatable, Hashable {
            /// Finnish layer name.
            public let fi: String
            /// Swedish layer name.
            public let sv: String
            /// English layer name.
            public let en: String
            
            /// Creates a localized layer name.
            /// - Parameters:
            ///   - fi: Finnish name.
            ///   - sv: Swedish name.
            ///   - en: English name.
            public init(fi: String, sv: String, en: String) {
                self.fi = fi
                self.sv = sv
                self.en = en
            }
        }
        
        // MARK: - LayerMetadata
        /// Metadata describing how to display feature properties from this layer.
        public struct LayerMetadata: Codable, Sendable, Equatable, Hashable {
            /// Property key containing the feature name.
            public let name: String
            /// Property keys to include in popup content (HTML template).
            public let popupContent: String
            /// Property key for plain text display.
            public let textOnly: String
            
            /// Creates layer metadata.
            /// - Parameters:
            ///   - name: Property key for feature names.
            ///   - popupContent: HTML template for popup content.
            ///   - textOnly: Property key for plain text content.
            public init(name: String, popupContent: String, textOnly: String) {
                self.name = name
                self.popupContent = popupContent
                self.textOnly = textOnly
            }
        }
        
        /// Creates a GeoJSON layer.
        /// - Parameters:
        ///   - name: Localized layer names.
        ///   - url: Relative URL to fetch layer data.
        ///   - metadata: Display metadata.
        public init(name: LayerName, url: String, metadata: LayerMetadata) {
            self.name = name
            self.url = url
            self.metadata = metadata
        }
        
        // MARK: - Computed Properties
        
        /// Full URL with HTTPS protocol prefix.
        ///
        /// The API returns protocol-relative URLs (starting with `//`).
        /// This property adds the `https:` prefix when needed.
        public var httpsURL: String {
            if url.hasPrefix("//") {
                return "https:\(url)"
            }
            return url
        }
    }
    
    // MARK: - GeoJSONLayersResponse
    /// Response wrapper for the GeoJSON layers endpoint.
    struct GeoJSONLayersResponse: Codable, Sendable, Equatable, Hashable {
        /// Container for the layers array.
        public let geojson: GeoJSONData
        
        /// Inner container holding the layers array.
        public struct GeoJSONData: Codable, Sendable, Equatable, Hashable {
            /// Available GeoJSON layers.
            public let layers: [GeoJSONLayer]
            
            /// Creates a GeoJSON data container.
            /// - Parameter layers: Array of available layers.
            public init(layers: [GeoJSONLayer]) {
                self.layers = layers
            }
        }
        
        /// Creates a layers response.
        /// - Parameter geojson: Container with layers array.
        public init(geojson: GeoJSONData) {
            self.geojson = geojson
        }
    }
}
