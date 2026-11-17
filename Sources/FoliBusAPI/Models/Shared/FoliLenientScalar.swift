import Foundation

/// A scalar Föli sends as a string today but that may arrive as a number.
///
/// Used for the undocumented `__`-prefixed extension fields, so a type change
/// upstream can't fail the whole vehicle or arrival decode.
struct FoliLenientScalar: Codable, Sendable, Hashable {
    let stringValue: String

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            stringValue = string
        } else if let int = try? container.decode(Int.self) {
            stringValue = String(int)
        } else {
            stringValue = String(try container.decode(Double.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
