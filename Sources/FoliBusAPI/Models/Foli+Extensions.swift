import Foundation
import CoreLocation
import SwiftUI

// MARK: - Namespace for Foli Data Models
/// Namespace containing all Foli data models
public enum Foli {}

// MARK: - CoreLocation Compatibility
public struct CLLocationCoordinate2D: Sendable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Convert to CoreLocation's CLLocationCoordinate2D
    public func toCLCoordinate() -> CoreLocation.CLLocationCoordinate2D {
        return CoreLocation.CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Color Helper for SwiftUI
extension SwiftUI.Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex string (e.g., "FF0000" or "#FF0000")
    public init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
