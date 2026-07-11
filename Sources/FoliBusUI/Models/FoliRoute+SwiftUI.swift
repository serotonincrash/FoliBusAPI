import SwiftUI
import FoliBusAPI

public extension Foli.Route {
    /// Route color as a SwiftUI `Color` if available.
    var color: Color? {
        guard let hexColor = colorHex, !hexColor.isEmpty else { return nil }
        return Color(hex: hexColor)
    }

    /// Route text color as a SwiftUI `Color` if available.
    var textColor: Color? {
        guard let hexColor = textColorHex, !hexColor.isEmpty else { return nil }
        return Color(hex: hexColor)
    }
}

extension SwiftUI.Color {
    /// Initialize a Color from a hex string.
    /// - Parameter hex: Hex string (e.g., "FF0000" or "#FF0000")
    internal init(hex: String) {
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
