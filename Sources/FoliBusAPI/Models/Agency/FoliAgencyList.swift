import Foundation

// MARK: - Agency List Response
extension Foli {
    /// Response containing all known agencies (GTFS agency.txt)
    struct AgencyList: Codable, Sendable, Equatable, Hashable {
        /// Array of all agencies
        let agencies: [Foli.Agency]

        init(agencies: [Foli.Agency]) {
            self.agencies = agencies
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let array = try container.decode([Foli.Agency].self)
            self.agencies = array.sorted { $0.id < $1.id }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(agencies)
        }
    }
}
