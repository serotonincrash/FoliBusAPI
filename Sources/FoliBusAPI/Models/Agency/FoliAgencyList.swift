import Foundation

// MARK: - Agency List Response
/// Response containing all known agencies (GTFS agency.txt)
public struct FoliAgencyList: Codable, Sendable {
    /// Array of all agencies
    public let agencies: [Foli.Agency]

    public init(agencies: [Foli.Agency]) {
        self.agencies = agencies
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Foli.Agency].self)
        self.agencies = array.sorted { $0.id < $1.id }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(agencies)
    }
}
